#!/usr/bin/env bash
#
# tools/publish-skills.sh
#
# Thin mechanical publishing layer for the agent-tools skill corpus.
# Consumes canonical content under src/ (with embedded agent markup)
# and emits clean, agent-specific trees under dist/<agent>/skills/.
#
# This script is intentionally minimal and dependency-free (pure bash + awk).
# It is designed to be called by setup.sh on every run.
#
# Usage:
#   tools/publish-skills.sh [--agents LIST] [--quiet] [--dry-run]
#
#   --agents   Comma-separated list of target agents
#              (default: claude,grok,factory,codex,opencode)
#   --quiet    Reduce output (only errors and warnings)
#   --dry-run  Show what would be published without writing files
#
# Environment (test seam):
#   AGENT_TOOLS_SRC_ROOT   Override the source tree (default: <repo>/src)
#   AGENT_TOOLS_DIST_ROOT  Override the output tree (default: <repo>/dist)
#
# Exit codes:
#   0  success (or only warnings)
#   1  fatal error
#

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# Overridable so tests can publish a fixture tree into a sandbox directory.
SRC_ROOT="${AGENT_TOOLS_SRC_ROOT:-${REPO_ROOT}/src}"
DIST_ROOT="${AGENT_TOOLS_DIST_ROOT:-${REPO_ROOT}/dist}"

# Directories under src/ that are not skills and should be ignored during publishing
SKIP_DIRS="pdf-build"

DEFAULT_AGENTS="claude,grok,factory,codex,opencode"

# Leaf skills (no sub-skills) that should be emitted only as direct commands for OpenCode
# (not as loadable skills). These are single-purpose invocables like /personify.
OPENCODE_LEAF_AS_COMMANDS="personify use-browser"
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
                   (opencode receives both skills/ and commands/ output)
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
#
# IMPORTANT: only used for agents whose discovery walks *only* direct children of skills/
# (Claude Code, Grok, Factory). Codex recursively discovers any SKILL.md under the tree,
# so emitting flats would duplicate every sub-skill. OpenCode never emits them here
# (it uses the separate commands/ mechanism instead).
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

# Write one OpenCode command .md from a SKILL.md: keep description frontmatter,
# drop other YAML keys, body is the skill body (frontmatter stripped).
write_opencode_command() {
    local skill_md="$1"
    local cmd_file="$2"
    local label="$3"   # short name for fallback description / log
    local log_kind="${4:-command}"  # "command" | "leaf command" | "family command"

    local desc
    desc=$(grep -m1 -i '^description:' "$skill_md" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$desc" ] && desc="Agent skill: ${label}"

    {
        echo "---"
        echo "description: ${desc}"
        echo "---"
        echo ""
        awk '
            BEGIN { seen_first = 0; in_frontmatter = 0 }
            /^---[ \t]*$/ {
                if (seen_first == 0) {
                    seen_first = 1
                    in_frontmatter = 1
                    next
                } else if (in_frontmatter) {
                    in_frontmatter = 0
                    next
                }
            }
            !in_frontmatter { print }
        ' "$skill_md"
    } > "$cmd_file"
    log "  → Emitted ${log_kind}: commands/$(basename "$cmd_file")"
}

# Emit native command definitions for OpenCode.
# OpenCode keeps "skills" (on-demand via the skill tool) and "commands" (explicit /slash
# triggers) as separate things. We emit:
#   1. Colon sub-skills (workflow:continue → workflow-continue)
#   2. Bare family roots that have colon-named children (workflow, swarm, git, …) so
#      /workflow and /swarm are real slash commands — not fuzzy-matched onto *-continue
#   3. Special leaf invocables (personify, use-browser)
# Family roots stay in skills/ (nested refs + skill-tool load). Leaves and
# colon-named top-level dirs are removed from skills/ after emission (see publish loop).
emit_commands_for_opencode() {
    local agent="$1"
    local skills_dir="$2"   # e.g. dist/opencode/skills (populated only in real runs)

    [[ "$agent" == "opencode" ]] || return

    local cmds_dir="${DIST_ROOT}/${agent}/commands"

    if [[ "$DRY_RUN" != true ]]; then
        rm -rf "$cmds_dir"
        mkdir -p "$cmds_dir"
    fi

    log "  Emitting OpenCode commands (families + sub-skills + leaves) for direct / invocation..."

    # In dry-run the dist trees are not created, so derive the list from src/.
    if [[ "$DRY_RUN" == true ]]; then
        for top in "$SRC_ROOT"/*/ ; do
            [[ -d "$top" ]] || continue
            local top_name
            top_name=$(basename "$top")
            [[ ",$SKIP_DIRS," == *",$top_name,"* ]] && continue

            local has_colon_sub=false
            for sub in "$top"/*/; do
                [[ -d "$sub" ]] || continue
                local sub_md="${sub}/SKILL.md"
                [[ -f "$sub_md" ]] || continue
                local declared
                declared=$(get_declared_name "$sub_md")
                if [[ "$declared" == *:* ]]; then
                    has_colon_sub=true
                    local flat="${declared//:/-}"
                    echo "    [dry] ${agent}/commands/${flat}.md"
                fi
            done

            # Bare family root (e.g. /workflow, /swarm) when it has colon-named children
            local top_md="${top}/SKILL.md"
            if [ -f "$top_md" ] && $has_colon_sub; then
                local top_declared
                top_declared=$(get_declared_name "$top_md")
                if [[ -n "$top_declared" && "$top_declared" != *:* ]]; then
                    echo "    [dry] ${agent}/commands/${top_declared}.md"
                fi
            fi

            # Top-level colon-named skill dirs (e.g. swarm-test → name: swarm:test)
            if [ -f "$top_md" ]; then
                local top_declared
                top_declared=$(get_declared_name "$top_md")
                if [[ "$top_declared" == *:* ]]; then
                    local flat="${top_declared//:/-}"
                    echo "    [dry] ${agent}/commands/${flat}.md"
                fi
            fi
        done

        # Special leaf commands (personify, use-browser) - no subskills, direct invocables
        for leaf in $OPENCODE_LEAF_AS_COMMANDS; do
            echo "    [dry] ${agent}/commands/${leaf}.md"
        done
        return
    fi

    # Real run: scan top-level published skill dirs (families and standalone).
    for top_dir in "$skills_dir"/*/; do
        [ -d "$top_dir" ] || continue
        local top_name
        top_name=$(basename "$top_dir")
        local top_md="${top_dir}/SKILL.md"
        local has_colon_sub=false

        # Direct children with colon names (e.g. workflow/continue → workflow-continue)
        for sub_dir in "$top_dir"/*/; do
            [ -d "$sub_dir" ] || continue
            local sub_md="${sub_dir}/SKILL.md"
            [ -f "$sub_md" ] || continue
            local declared
            declared=$(get_declared_name "$sub_md")
            if [[ "$declared" == *:* ]]; then
                has_colon_sub=true
                local flat="${declared//:/-}"
                write_opencode_command "$sub_md" "${cmds_dir}/${flat}.md" "$flat" "command"
            fi
        done

        # Top-level dir itself:
        # - colon-named standalone (swarm-test) → command only (removed from skills later)
        # - bare family root with colon children (workflow) → command + keep in skills/
        if [ -f "$top_md" ]; then
            local declared
            declared=$(get_declared_name "$top_md")
            if [[ "$declared" == *:* ]]; then
                local flat="${declared//:/-}"
                write_opencode_command "$top_md" "${cmds_dir}/${flat}.md" "$flat" "command"
            elif [[ -n "$declared" && "$declared" != *:* ]] && $has_colon_sub; then
                write_opencode_command "$top_md" "${cmds_dir}/${declared}.md" "$declared" "family command"
            fi
        fi
    done

    # Special leaf commands for opencode (e.g. personify, use-browser).
    # These are top-level skills with no sub-skills. Emit them as commands (using
    # their own name) and they will be removed from skills/ below to avoid duplication.
    for leaf in $OPENCODE_LEAF_AS_COMMANDS; do
        local leaf_dir="${skills_dir}/${leaf}"
        local leaf_md="${leaf_dir}/SKILL.md"
        if [ -f "$leaf_md" ]; then
            write_opencode_command "$leaf_md" "${cmds_dir}/${leaf}.md" "$leaf" "leaf command"
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
    # All other HTML comments outside fenced code are stripped (fenced
    # examples and backticked comment literals publish verbatim).
    #
    # We keep the implementation intentionally straightforward.

    awk -v agent="$agent" '
        BEGIN {
            IGNORECASE = 1
            in_include = 0
            in_exclude = 0
            include_active = 0
            exclude_active = 0
            in_comment = 0
            in_fence = 0
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

        # Print a line subject to the active include/exclude region
        function emit(line) {
            if (in_include) {
                if (include_active) print line
            } else if (in_exclude) {
                if (!exclude_active) print line
            } else {
                print line
            }
        }

        # Continuation of a multi-line HTML comment (must run before the
        # fence and tag rules: inside a comment, everything is comment
        # content until the closer)
        in_comment == 1 {
            if ((j = index($0, "-->")) > 0) {
                $0 = substr($0, j + 3)
                in_comment = 0
                if ($0 ~ /^[ \t]*$/) next
            } else {
                next
            }
        }

        # Fenced code blocks publish verbatim: tags inside them are
        # documentation examples, and their comments are literal content.
        # Region filtering still applies (a fence inside an inactive
        # include region is dropped with the region).
        /^[ \t]*(```|~~~)/ {
            in_fence = !in_fence
            emit($0)
            next
        }

        in_fence == 1 {
            emit($0)
            next
        }

        # Opening include tag (tags must be on their own line; prose or
        # backticked mentions elsewhere on a line are never directives)
        /^[ \t]*<!--[ \t]*agent:include[ \t]/ {
            list = extract_list($0)
            in_include = 1
            include_active = agent_in_list(list)
            next
        }

        # Closing include tag (allow optional whitespace and agent list after the tag)
        /^[ \t]*<!--[ \t]*\/agent:include/ {
            in_include = 0
            include_active = 0
            next
        }

        # Opening exclude tag
        /^[ \t]*<!--[ \t]*agent:exclude[ \t]/ {
            list = extract_list($0)
            in_exclude = 1
            exclude_active = agent_in_list(list)
            next
        }

        # Closing exclude tag (allow optional whitespace and agent list after the tag)
        /^[ \t]*<!--[ \t]*\/agent:exclude/ {
            in_exclude = 0
            exclude_active = 0
            next
        }

        # Strip all remaining HTML comments (agent: tags were handled
        # above): inline comments are removed with surrounding text
        # preserved; comment literals inside backtick code spans are kept;
        # an unterminated opener starts a multi-line comment; a line left
        # empty after stripping is dropped entirely.
        /<!--/ {
            nseg = split($0, seg, /`/)
            res = ""
            dropped = 0
            for (s = 1; s <= nseg; s++) {
                piece = seg[s]
                if (s % 2 == 1) {
                    outp = ""
                    line = piece
                    while ((i = index(line, "<!--")) > 0) {
                        outp = outp substr(line, 1, i - 1)
                        rest = substr(line, i)
                        if ((j = index(rest, "-->")) > 0) {
                            line = substr(rest, j + 3)
                        } else {
                            in_comment = 1
                            line = ""
                            dropped = 1
                            break
                        }
                    }
                    piece = outp line
                }
                res = res piece
                if (dropped) break
                if (s < nseg) res = res "`"
            }
            $0 = res
            sub(/[ \t]+$/, "", $0)
            if ($0 ~ /^[ \t]*$/) next
        }

        # Normal content lines
        {
            emit($0)
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
            rel_path="${src_path#"${skill_dir}"}"
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
        # (e.g. src/git/commit/SKILL.md with name: git:commit  →  dist/.../skills/git-commit/).
        #
        # Only for agents that do not support recursive discovery inside skill directories.
        # Codex recurses (so the nested tree written above is sufficient and prevents dups).
        # OpenCode uses commands/ exclusively for subs.
        if [[ "$agent" != "opencode" && "$agent" != "codex" ]]; then
            emit_flattened_leaves "$agent" "$skill_name" "$dest_skill_dir"
        fi
    done

    # For OpenCode, emit the sub-skill (colon) invocables as native commands.
    # See emit_commands_for_opencode for rationale. (We never create hyphenated skill dirs for opencode.)
    if [[ "$agent" == "opencode" ]]; then
        emit_commands_for_opencode "$agent" "$dest_dir"

        # After emitting commands, remove any top-level dirs in skills/ that we want
        # only as commands for opencode (prevents duplication):
        # - Colon-named sub-skills (e.g. swarm-test, workflow-continue)
        # - Special leaf commands without sub-skills (personify, use-browser)
        for d in "$dest_dir"/*/; do
            [ -d "$d" ] || continue
            local nm
            nm=$(basename "$d")
            local md="$d/SKILL.md"
            local should_remove=false
            if [ -f "$md" ]; then
                local decl
                decl=$(get_declared_name "$md")
                if [[ "$decl" == *:* ]]; then
                    should_remove=true
                fi
            fi
            # Check against the explicit leaf command list
            for leaf in $OPENCODE_LEAF_AS_COMMANDS; do
                if [[ "$nm" == "$leaf" ]]; then
                    should_remove=true
                    break
                fi
            done
            if $should_remove; then
                rm -rf "$d"
                log "  → Removed ${nm}/ from opencode skills (only as command)"
            fi
        done
    fi

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
log "Output: $DIST_ROOT (commands/ also emitted for opencode)"
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
