#!/usr/bin/env bash
#
# tools/publish-skills.sh
#
# Thin mechanical publishing layer for the agent-tools skill corpus.
# Consumes canonical content under src/skills/ (with embedded agent markup)
# and emits clean, agent-specific trees under dist/<agent>/skills/.
#
# This script is intentionally minimal and dependency-free (pure bash + awk).
# It is designed to be called by setup.sh on every run.
#
# Usage:
#   tools/publish-skills.sh [--agents claude,grok,factory] [--quiet]
#
#   --agents   Comma-separated list of target agents (default: claude,grok,factory)
#   --quiet    Reduce output (only errors and warnings)
#
# Exit codes:
#   0  success (or only warnings)
#   1  fatal error
#

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_ROOT="${REPO_ROOT}/src"
DIST_ROOT="${REPO_ROOT}/dist"

# Directories under src/ that are not skills and should be ignored during publishing
SKIP_DIRS="pdf-build"

DEFAULT_AGENTS="claude,grok,factory"
QUIET=false
DRY_RUN=false

# ── Argument parsing ─────────────────────────────────────────────────

AGENTS="$DEFAULT_AGENTS"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --agents)
            AGENTS="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            QUIET=false
            shift
            ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --agents LIST    Comma-separated list of agents (default: $DEFAULT_AGENTS)
  --quiet          Suppress non-error output
  --dry-run        Show what would be published without writing files
  -h, --help       Show this help message

The script always publishes for the requested agents into dist/<agent>/skills/.
It is the caller's responsibility (usually setup.sh) to decide what to symlink
and where (user profile vs local project).
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Normalize agents to lowercase, comma-separated, no spaces
AGENTS=$(echo "$AGENTS" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

# ── Helpers ──────────────────────────────────────────────────────────

log() {
    if [[ "$QUIET" != true ]]; then
        echo -e "$*"
    fi
}

warn() {
    echo -e "\033[1;33mWarning:\033[0m $*" >&2
}

error() {
    echo -e "\033[0;31mError:\033[0m $*" >&2
}

fatal() {
    error "$*"
    exit 1
}

# Check that required tools exist (portability)
require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fatal "Required tool not found: $1 (needed for cross-platform operation)"
    fi
}

require_tool awk
require_tool find
require_tool mkdir
require_tool cp
require_tool rm

# Extract the declared "name:" from a SKILL.md (used for colon-name flattening)
get_declared_name() {
    local file="$1"
    if [ -f "$file" ]; then
        grep -m1 '^name:' "$file" | cut -d: -f2- | tr -d ' \t\r\n'
    fi
}

# After a grouped package has been published (e.g. dist/.../skills/git/),
# look for any leaf sub-skills whose name contains a colon (git:commit, workflow:refine, etc.)
# and also publish them as top-level skills using hyphen as separator (git-commit, workflow-refine).
# This allows both the group overview (/git) and direct sub-commands (/git-commit) to appear.
emit_flattened_leaves() {
    local agent="$1"
    local package="$2"          # e.g. "git", "workflow"
    local group_dir="$3"        # e.g. dist/claude/skills/git

    for leaf_dir in "$group_dir"/*/; do
        [ -d "$leaf_dir" ] || continue
        local leaf_name
        leaf_name=$(basename "$leaf_dir")

        local skill_md="$leaf_dir/SKILL.md"
        [ -f "$skill_md" ] || continue

        local declared_name
        declared_name=$(get_declared_name "$skill_md")

        if [[ "$declared_name" == *:* ]]; then
            local flat_name="${declared_name//:/-}"     # git:commit → git-commit
            local flat_dest="${DIST_ROOT}/${agent}/skills/${flat_name}"

            if [[ "$DRY_RUN" == true ]]; then
                echo "    [dry] ${agent}/${flat_name}/ (flattened from ${package}/${leaf_name})"
                continue
            fi

            rm -rf "$flat_dest"
            mkdir -p "$flat_dest"
            cp -a "$leaf_dir"/* "$flat_dest"/ 2>/dev/null || true
            log "  → Also published flattened leaf: ${flat_name}/"
        fi
    done
}

# ── Core filtering logic (awk) ───────────────────────────────────────
#
# For each target agent we run the source files through this filter.
# It implements the rules defined in src/skills/references/MARKUP.md.
#

filter_for_agent() {
    local agent="$1"
    local input_file="$2"

    # The awk program below is a state machine that handles:
    #   <!-- agent:include X,Y --> ... <!-- /agent:include X,Y -->
    #   <!-- agent:exclude X,Y --> ... <!-- /agent:exclude X,Y -->
    # All other HTML comments are stripped in the final output.
    #
    # We keep the implementation intentionally straightforward.

    awk -v agent="$agent" '
        BEGIN {
            IGNORECASE = 1
            in_include = 0
            in_exclude = 0
            include_active = 0
            exclude_active = 0
        }

        function agent_in_list(list) {
            gsub(/[ \t]/, "", list)
            n = split(list, arr, /,/)
            for (i = 1; i <= n; i++) {
                if (arr[i] == agent) return 1
            }
            return 0
        }

        # Extract the agent list from a tag line more defensively
        function extract_list(line,   tag, list) {
            # Remove everything up to and including "agent:include" or "agent:exclude"
            sub(/.*agent:(include|exclude)[ \t]*/, "", line)
            # Remove from HTML comment closer "-->" or ">" onward (tags end with " -->")
            sub(/[ \t]*-->.*/, "", line)
            sub(/[ \t]*>.*/, "", line)
            gsub(/[ \t]/, "", line)
            return line
        }

        # Opening include tag
        /<!--[ \t]*agent:include[ \t]/ {
            list = extract_list($0)
            in_include = 1
            include_active = agent_in_list(list)
            next
        }

        # Closing include tag (allow optional whitespace and agent list after the tag)
        /<!--[ \t]*\/agent:include/ {
            in_include = 0
            include_active = 0
            next
        }

        # Opening exclude tag
        /<!--[ \t]*agent:exclude[ \t]/ {
            list = extract_list($0)
            in_exclude = 1
            exclude_active = agent_in_list(list)
            next
        }

        # Closing exclude tag (allow optional whitespace and agent list after the tag)
        /<!--[ \t]*\/agent:exclude/ {
            in_exclude = 0
            exclude_active = 0
            next
        }

        # Any other HTML comment line -> strip entirely
        /<!--.*-->/ {
            # We already handled the agent: tags above.
            # Any remaining comment-only lines are discarded.
            next
        }

        # Normal content lines
        {
            if (in_include) {
                if (include_active) print
            } else if (in_exclude) {
                if (!exclude_active) print
            } else {
                print
            }
        }
    ' "$input_file"
}

# ── Main publishing routine ──────────────────────────────────────────

publish_for_agent() {
    local agent="$1"
    local dest_dir="${DIST_ROOT}/${agent}/skills"

    log "Publishing for agent: ${agent}"

    if [[ "$DRY_RUN" != true ]]; then
        rm -rf "$dest_dir"
        mkdir -p "$dest_dir"
    fi

    # Walk each top-level directory under src/ (these are the skills)
    for skill_dir in "$SRC_ROOT"/*/ ; do
        [[ -d "$skill_dir" ]] || continue

        skill_name=$(basename "$skill_dir")

        # Skip non-skill directories
        if [[ ",$SKIP_DIRS," == *",$skill_name,"* ]]; then
            continue
        fi

        dest_skill_dir="${dest_dir}/${skill_name}"

        if [[ "$DRY_RUN" != true ]]; then
            mkdir -p "$dest_skill_dir"
        fi

        # Recursively process everything inside this skill
        while IFS= read -r -d '' src_path; do
            rel_path="${src_path#${skill_dir}}"
            dest_path="${dest_skill_dir}/${rel_path}"

            if [[ -d "$src_path" ]]; then
                if [[ "$DRY_RUN" != true ]]; then
                    mkdir -p "$dest_path"
                fi
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                local display_rel="${rel_path}"
                [[ "$display_rel" != /* ]] && display_rel="/$display_rel"
                echo "    [dry] ${agent}/${skill_name}${display_rel}"
                continue
            fi

            mkdir -p "$(dirname "$dest_path")"

            if [[ "$src_path" == *.md ]]; then
                filter_for_agent "$agent" "$src_path" > "$dest_path"
            else
                cp "$src_path" "$dest_path"
            fi

        done < <(find "$skill_dir" -print0)

        # Emit flattened top-level versions for any sub-skills that use colon namespacing
        # (e.g. src/git/commit/SKILL.md with name: git:commit  →  dist/.../skills/git-commit/)
        #
        # For Grok we currently skip this because the plugin/raw indexer does not
        # promote the hyphenated siblings as first-class top-level commands the way
        # Claude does. We emit them only for agents where they improve discoverability.
        if [[ "$agent" != "grok" ]]; then
            emit_flattened_leaves "$agent" "$skill_name" "$dest_skill_dir"
        fi
    done

    if [[ "$DRY_RUN" != true ]]; then
        local count
        count=$(find "$dest_dir" -type f | wc -l | tr -d ' ')
        log "  → ${count} files written to dist/${agent}/skills/"
    fi
}

# ── Execution ────────────────────────────────────────────────────────

if [[ ! -d "$SRC_ROOT" ]]; then
    fatal "Source directory not found: $SRC_ROOT"
fi

log "Agent-tools skill publisher"
log "Source: $SRC_ROOT"
log "Output: $DIST_ROOT"
log ""

IFS=',' read -ra AGENT_LIST <<< "$AGENTS"

for agent in "${AGENT_LIST[@]}"; do
    # Basic validation of agent name
    if [[ ! "$agent" =~ ^[a-z0-9-]+$ ]]; then
        warn "Skipping invalid agent name: '$agent'"
        continue
    fi

    publish_for_agent "$agent"
done

log ""
if [[ "$DRY_RUN" == true ]]; then
    log "Dry run complete (no files written)."
else
    log "Publishing complete."
fi

# Always succeed unless a fatal error occurred earlier
exit 0
