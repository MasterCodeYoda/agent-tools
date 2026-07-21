#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            echo "Usage: setup.sh"
            echo ""
            echo "  Re-publishes skills from src/ into dist/<agent>/skills/,"
            echo "  then installs (symlinks) them into your user profile for any"
            echo "  detected agents (Claude, Grok, Factory, OpenCode)."
            echo "  For OpenCode, sub-skills are also emitted as native commands."
            echo ""
            echo "Options:"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run setup.sh --help for usage."
            exit 1
            ;;
    esac
done

# ── Source and target directories ───────────────────────────────────
SKILLS_SOURCE="${SCRIPT_DIR}/src"
DIST_BASE="${SCRIPT_DIR}/dist"

# Note: The canonical source is under src/. The publisher (tools/publish-skills.sh)
# transforms it into dist/<agent>/skills/ with agent-specific markup resolved.
# setup.sh now consumes from dist/ rather than src/ directly.

CLAUDE_DIR="${HOME}/.claude"
GROK_DIR="${HOME}/.grok"
# Grok also supports ~/.grok/skills directly in some installations
GROK_SKILLS_DIR="${HOME}/.grok/skills"
FACTORY_DIR="${HOME}/.factory"
CODEX_DIR="${HOME}/.codex"

# OpenCode uses XDG-style config for global files. Project layout is .opencode/
# We support both skills (for the native `skill` tool) and commands (for direct /slash).
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Marker file placed inside every skill installed by this repo.
# Used to safely identify and prune stale skills on future runs.
MANAGED_MARKER=".agent-tools"

# Compute the correct skills directory for an agent (user vs project).
# OpenCode is special: global uses ~/.config/opencode/skills (XDG), project uses .opencode/skills
get_agent_skills_dir() {
    local agent="$1"
    local scope="$2"   # "user" or "project"
    if [ "$agent" = "opencode" ]; then
        if [ "$scope" = "project" ]; then
            echo "${SCRIPT_DIR}/.opencode/skills"
        else
            echo "${HOME}/.config/opencode/skills"
        fi
    else
        if [ "$scope" = "project" ]; then
            echo "${SCRIPT_DIR}/.${agent}/skills"
        else
            echo "${HOME}/.${agent}/skills"
        fi
    fi
}

# ── Helpers ─────────────────────────────────────────────────────────

# Create a symlink with proper error handling (used for ~/.claude only)
create_symlink() {
    local source="$1"
    local target="$2"
    local parent_dir
    parent_dir="$(dirname "$target")"

    # Create parent directory if it doesn't exist
    if [ ! -d "$parent_dir" ]; then
        echo -e "${YELLOW}Creating directory: ${parent_dir}${NC}"
        mkdir -p "$parent_dir"
    fi

    # Check if target already exists
    if [ -L "$target" ]; then
        # It's a symlink
        current_target=$(readlink "$target")
        if [ "$current_target" = "$source" ]; then
            echo -e "${GREEN}✓${NC} Symlink already exists: $target -> $source"
        else
            echo -e "${YELLOW}⚠${NC}  Symlink exists but points elsewhere: $target -> $current_target"
            read -p "Replace with new symlink? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$target"
                ln -s "$source" "$target"
                echo -e "${GREEN}✓${NC} Updated symlink: $target -> $source"
            else
                echo -e "${YELLOW}Skipped: $target${NC}"
            fi
        fi
    elif [ -e "$target" ]; then
        # Something else exists at the target
        echo -e "${RED}✗${NC} Path exists and is not a symlink: $target"
        read -p "Replace with symlink? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$target"
            ln -s "$source" "$target"
            echo -e "${GREEN}✓${NC} Created symlink: $target -> $source"
        else
            echo -e "${YELLOW}Skipped: $target${NC}"
        fi
    else
        # Target doesn't exist, create symlink
        ln -s "$source" "$target"
        echo -e "${GREEN}✓${NC} Created symlink: $target -> $source"
    fi
}



# ── Per-skill installation with publish-target support ─────────────

# Extract publish-target from a skill's SKILL.md (defaults to user-profile)
get_publish_target() {
    local skill_path="$1"          # e.g. dist/claude/skills/workflow or src/...
    local skill_md="${skill_path}/SKILL.md"

    if [ -f "$skill_md" ]; then
        local val
        val=$(grep -iE '^publish-target:' "$skill_md" | head -1 | cut -d: -f2- | tr -d ' \t\r\n' | tr '[:upper:]' '[:lower:]')
        if [ -n "$val" ]; then
            echo "$val"
            return
        fi
    fi
    echo "user-profile"
}

# Resolve publish-target for a published skill dir, inheriting project scope from the
# family package when a flattened leaf (e.g. skills-evolve) omits the frontmatter key.
# Family name is the prefix before the first hyphen: skills-evolve → skills.
resolve_skill_publish_target() {
    local agent="$1"
    local skill_name="$2"
    local source_skill_dir="$3"

    local publish_target
    publish_target=$(get_publish_target "$source_skill_dir")

    if [ "$publish_target" = "user-profile" ] && [[ "$skill_name" == *-* ]]; then
        local family="${skill_name%%-*}"
        local family_dir="${DIST_BASE}/${agent}/skills/${family}"
        if [ -d "$family_dir" ]; then
            local pt
            pt=$(get_publish_target "$family_dir")
            if [ "$pt" = "project" ]; then
                publish_target="project"
            fi
        fi
    fi
    echo "$publish_target"
}

# True if path is an agent-tools managed skill install (marker and/or symlink into our dist).
is_managed_skill_entry() {
    local entry="$1"
    local agent="$2"
    if [ -e "${entry}/${MANAGED_MARKER}" ]; then
        return 0
    fi
    if [ -L "$entry" ]; then
        local link_target
        link_target=$(readlink "$entry" 2>/dev/null || true)
        if [[ -n "$link_target" && "$link_target" == *"/dist/${agent}/skills/"* ]]; then
            return 0
        fi
    fi
    return 1
}

# Remove a managed skill install from a scope (used to migrate project-scoped leaves
# out of the user profile after they were incorrectly installed globally).
remove_managed_skill_entry() {
    local entry="$1"
    local agent="$2"
    local label="$3"
    if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
        return
    fi
    if is_managed_skill_entry "$entry" "$agent"; then
        echo -e "  ${YELLOW}→${NC} Removing ${label}: ${entry}"
        rm -rf "$entry"
    fi
}

# Install a single skill directory for a given agent
install_skill() {
    local agent="$1"               # claude, grok, factory, codex, opencode
    local skill_name="$2"          # e.g. "workflow", "skills"
    local source_skill_dir="$3"    # e.g. dist/claude/skills/workflow

    local publish_target
    publish_target=$(resolve_skill_publish_target "$agent" "$skill_name" "$source_skill_dir")

    local target_base
    local scope_label
    local other_base

    if [ "$publish_target" = "project" ]; then
        target_base=$(get_agent_skills_dir "$agent" "project")
        other_base=$(get_agent_skills_dir "$agent" "user")
        scope_label="${YELLOW}[project]${NC}"

        if [ ! -d "$target_base" ]; then
            mkdir -p "$target_base"
            local pretty
            if [ "$agent" = "opencode" ]; then
                pretty=".opencode/skills/"
            else
                pretty=".${agent}/skills/"
            fi
            echo -e "  ${YELLOW}→${NC} Created local project directory: ${pretty} (for project-scoped skills)"
        fi
    else
        target_base=$(get_agent_skills_dir "$agent" "user")
        other_base=$(get_agent_skills_dir "$agent" "project")
        scope_label="[user]"
    fi

    local target="${target_base}/${skill_name}"

    # Print clean one-line status (consistent across all agents)
    echo -e "  ${scope_label} ${skill_name}  →  ${target}"

    mkdir -p "$(dirname "$target")"

    # If a real directory exists at the target (e.g. old rsync copies for Factory),
    # remove it so we can install a clean symlink. This is the one-time migration path.
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Replacing real directory at ${target} with symlink (migrating from previous copy)"
        rm -rf "$target"
    fi

    # Symlink, replacing if needed (non-interactive for normal setup flow)
    # All agents (Claude, Grok, Factory) now use the same symlink model from dist/<agent>/skills/
    ln -sfn "$source_skill_dir" "$target"

    # Mark this skill as managed by agent-tools so future runs can safely prune it if removed.
    touch "${target}/${MANAGED_MARKER}"

    # Drop a stale copy from the other scope (e.g. project leaf previously leaked to ~/.claude/skills).
    remove_managed_skill_entry "${other_base}/${skill_name}" "$agent" "wrong-scope install of ${skill_name}"
}

# Prune skills that were previously installed by this repo (have the marker)
# but no longer exist in the current published set for this agent.
prune_stale_skills() {
    local agent="$1"
    local target_base="$2"          # e.g. ~/.claude/skills or ./.claude/skills
    local dist_agent_dir="$3"       # e.g. dist/claude/skills

    [ -d "$target_base" ] || return

    local current_published=()
    if [ -d "$dist_agent_dir" ]; then
        for d in "$dist_agent_dir"/*/; do
            [ -d "$d" ] && current_published+=("$(basename "$d")")
        done
    fi

    local removed=0
    for entry in "$target_base"/*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        local name
        name=$(basename "$entry")

        # Only consider directories or symlinks that look like skills
        if [ -d "$entry" ] || [ -L "$entry" ]; then
            local marker="${entry}/${MANAGED_MARKER}"
            local still_published=false
            local is_ours=false

            if [ -e "$marker" ]; then
                is_ours=true
                for pub in "${current_published[@]}"; do
                    if [ "$pub" = "$name" ]; then
                        still_published=true
                        break
                    fi
                done
            elif [ -L "$entry" ]; then
                # Dangling (or target-missing) symlink. Check if it pointed into our
                # dist tree for this agent (covers removed flats, legacy layouts, etc.).
                local link_target
                link_target=$(readlink "$entry" 2>/dev/null || true)
                if [[ -n "$link_target" && "$link_target" == *"/dist/${agent}/skills/"* ]]; then
                    is_ours=true
                    for pub in "${current_published[@]}"; do
                        if [ "$pub" = "$name" ]; then
                            still_published=true
                            break
                        fi
                    done
                fi
            fi

            if [ "$is_ours" = true ] && [ "$still_published" = false ]; then
                echo -e "  ${YELLOW}→${NC} Removing stale managed skill: ${name}"
                rm -rf "$entry"
                ((removed++))
            fi
        fi
    done

    if [ "$removed" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Pruned ${removed} stale skill(s) from ${target_base}"
    fi
}

# Install all skills for one agent from dist/
install_skills_for_agent() {
    local agent="$1"
    local dist_agent_dir="${DIST_BASE}/${agent}/skills"

    if [ ! -d "$dist_agent_dir" ]; then
        echo -e "${YELLOW}No published content for ${agent}${NC}"
        return
    fi

    echo "Installing skills for ${agent}..."

    # Handle legacy installation where ~/.${agent}/skills was a symlink to an entire
    # old skills tree. The new model uses a real directory containing one symlink
    # per skill (pointing into dist/<agent>/skills/<skill>/). Remove the old symlink
    # so we can create a proper directory.
    # OpenCode uses ~/.config/opencode/skills so we only do the legacy .${agent} cleanup for non-opencode.
    local user_skills_dir
    user_skills_dir=$(get_agent_skills_dir "$agent" "user")
    if [ "$agent" != "opencode" ] && [ -L "$user_skills_dir" ]; then
        echo -e "${YELLOW}⚠${NC}  Replacing legacy whole-skills symlink: ${user_skills_dir} (migrating to per-skill layout)"
        rm -f "$user_skills_dir"
    fi

    for skill_dir in "${dist_agent_dir}"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name=$(basename "$skill_dir")

        install_skill "$agent" "$skill_name" "$skill_dir"
    done

    # Prune any previously managed skills that are no longer published.
    # This safely removes old entries (including legacy flat skills, dangling
    # symlinks to removed dist entries, and any renamed/removed grouped or
    # flattened skills) without touching third-party skills.
    local user_target
    user_target=$(get_agent_skills_dir "$agent" "user")
    local project_target
    project_target=$(get_agent_skills_dir "$agent" "project")

    prune_stale_skills "$agent" "$user_target" "$dist_agent_dir"
    prune_stale_skills "$agent" "$project_target" "$dist_agent_dir"

    echo
}

# Resolve publish-target for an OpenCode command name (skills-evolve, swarm-test, …).
resolve_opencode_command_publish_target() {
    local cmd_name="$1"
    local corresponding_skill="${DIST_BASE}/opencode/skills/${cmd_name}"
    local publish_target
    publish_target=$(get_publish_target "$corresponding_skill")

    if [ "$publish_target" = "user-profile" ]; then
        # Flattened leaf not in opencode skills/; inherit from family package or src.
        if [[ "$cmd_name" == *-* ]]; then
            local family="${cmd_name%%-*}"
            local family_skill="${DIST_BASE}/opencode/skills/${family}"
            if [ -d "$family_skill" ]; then
                local pt
                pt=$(get_publish_target "$family_skill")
                if [ "$pt" = "project" ]; then
                    publish_target="project"
                fi
            fi
        fi
    fi
    if [ "$publish_target" = "user-profile" ]; then
        # Exact declared-name match in src/ — "swarm" must not hit "swarm:test".
        local src_name="${cmd_name//-/:}"
        while IFS= read -r src_md; do
            local declared
            declared=$(grep -m1 '^name:' "$src_md" 2>/dev/null | cut -d: -f2- | tr -d ' \t\r\n')
            if [ "$declared" = "$src_name" ]; then
                local src_dir
                src_dir=$(dirname "$src_md")
                local pt
                pt=$(get_publish_target "$src_dir")
                if [ "$pt" = "project" ]; then
                    publish_target="project"
                    break
                fi
                local parent_dir
                parent_dir=$(dirname "$src_dir")
                pt=$(get_publish_target "$parent_dir")
                if [ "$pt" = "project" ]; then
                    publish_target="project"
                    break
                fi
            fi
        done < <(find "${SCRIPT_DIR}/src" -name SKILL.md 2>/dev/null)
    fi
    echo "$publish_target"
}

# Install OpenCode command definitions (flat .md files for direct /command invocation).
# Commands are emitted by the publisher only for the "opencode" target.
# We respect publish-target the same way as skills (most go to user global;
# the project-scoped meta skills go to the local .opencode/commands/).
install_commands_for_agent() {
    local agent="$1"
    [[ "$agent" == "opencode" ]] || return

    local dist_cmds_dir="${DIST_BASE}/${agent}/commands"
    if [ ! -d "$dist_cmds_dir" ]; then
        echo -e "${YELLOW}No commands published for ${agent}${NC}"
        return
    fi

    echo "Installing commands for ${agent}..."

    local project_cmds="${SCRIPT_DIR}/.opencode/commands"
    local user_cmds="${HOME}/.config/opencode/commands"
    local published_cmds=()

    for cmd_file in "${dist_cmds_dir}"/*.md; do
        [ -f "$cmd_file" ] || continue
        local cmd_name
        cmd_name=$(basename "$cmd_file" .md)
        published_cmds+=("$cmd_name")

        local publish_target
        publish_target=$(resolve_opencode_command_publish_target "$cmd_name")

        local target_base
        local other_base
        if [ "$publish_target" = "project" ]; then
            target_base="$project_cmds"
            other_base="$user_cmds"
        else
            target_base="$user_cmds"
            other_base="$project_cmds"
        fi

        mkdir -p "$target_base"
        local target="${target_base}/${cmd_name}.md"

        echo "  ${cmd_name} → ${target}"
        ln -sfn "$cmd_file" "$target"

        # Migrate: remove managed/wrong-scope copy (e.g. stale global swarm-test.md).
        local other="${other_base}/${cmd_name}.md"
        if [ -L "$other" ] || [ -f "$other" ]; then
            local other_link
            other_link=$(readlink "$other" 2>/dev/null || true)
            if [[ -z "$other_link" || "$other_link" == *"/dist/opencode/commands/"* ]]; then
                echo -e "  ${YELLOW}→${NC} Removing wrong-scope command: ${other}"
                rm -f "$other"
            fi
        fi
    done

    # Prune managed user-global commands no longer published (or left after renames).
    if [ -d "$user_cmds" ]; then
        local removed=0
        for entry in "$user_cmds"/*; do
            [ -e "$entry" ] || [ -L "$entry" ] || continue
            [[ "$entry" == *.md ]] || continue
            local name
            name=$(basename "$entry" .md)
            local still=false
            for pub in "${published_cmds[@]}"; do
                if [ "$pub" = "$name" ]; then
                    still=true
                    break
                fi
            done
            if [ "$still" = false ]; then
                local link_target
                link_target=$(readlink "$entry" 2>/dev/null || true)
                if [[ "$link_target" == *"/dist/opencode/commands/"* ]]; then
                    echo -e "  ${YELLOW}→${NC} Removing stale managed command: ${entry}"
                    rm -f "$entry"
                    ((removed++))
                fi
            fi
        done
        if [ "$removed" -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} Pruned ${removed} stale OpenCode command(s) from ${user_cmds}"
        fi
    fi

    echo
}

# ── Main execution ──────────────────────────────────────────────────

validate_sources() {
    if [ ! -d "$SKILLS_SOURCE" ]; then
        echo -e "${RED}Error: Skills directory not found at $SKILLS_SOURCE${NC}" >&2
        exit 1
    fi
    if [ ! -x "${SCRIPT_DIR}/tools/publish-skills.sh" ]; then
        echo -e "${RED}Error: Publisher not found or not executable: tools/publish-skills.sh${NC}" >&2
        exit 1
    fi
}

# ── Publishing step ─────────────────────────────────────────────────

run_publisher() {
    local publisher="${SCRIPT_DIR}/tools/publish-skills.sh"

    echo "Publishing skills for all agents (claude, grok, factory, codex, opencode)..."
    # Unset the test-seam overrides: setup.sh symlinks from its own dist/,
    # so a leaked override would silently publish elsewhere and install
    # stale trees.
    if env -u AGENT_TOOLS_SRC_ROOT -u AGENT_TOOLS_DIST_ROOT "$publisher" --quiet; then
        echo -e "${GREEN}✓${NC} Publishing complete → dist/<agent>/skills/"
    else
        echo -e "${RED}✗${NC} Publishing failed. Aborting setup." >&2
        exit 1
    fi
    echo
}

# Full setup for all present agents
validate_sources
run_publisher

echo "========================================="
echo "Setting up agent-tools"
echo "========================================="
echo

# Agent detection is based *only* on the user's global settings directories.
# If an agent is installed globally, we deploy both user-profile skills
# (to ~/.agent/skills) and project-scoped skills (to ./.agent/skills in this repo),
# creating the local project directory if it doesn't exist yet.
# Codex detection uses ~/.codex (its home for AGENTS.md/config; skills install to ~/.codex/skills/ per current support choice).
if [ -d "$CLAUDE_DIR" ]; then
    install_skills_for_agent "claude"
fi

# Grok detection is slightly more lenient because the .grok directory
# layout is newer and some users have ~/.grok/skills directly.
if [ -d "$GROK_DIR" ] || [ -d "$GROK_SKILLS_DIR" ]; then
    install_skills_for_agent "grok"
fi

if [ -d "$FACTORY_DIR" ]; then
    install_skills_for_agent "factory"
fi

if [ -d "$CODEX_DIR" ]; then
    install_skills_for_agent "codex"
fi

# OpenCode detection: look for the global config dir or a local .opencode project dir.
# We also install commands (in addition to skills) for direct /slash support.
if [ -d "$OPENCODE_CONFIG_DIR" ] || [ -d "${SCRIPT_DIR}/.opencode" ]; then
    install_skills_for_agent "opencode"
    install_commands_for_agent "opencode"
fi

# Clean up legacy factory-commands/ directory in the repo (one-time)
if [ -d "${SCRIPT_DIR}/factory-commands" ]; then
    rm -rf "${SCRIPT_DIR}/factory-commands"
    echo -e "${GREEN}✓${NC} Removed legacy factory-commands/ directory"
fi

echo

echo "========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "========================================="
echo
echo "Configured (from dist/<agent>/skills/):"
echo
if [ -d "$CLAUDE_DIR" ]; then
    echo "  Claude:"
    echo "    - User profile : ~/.claude/skills/"
    echo "    - This project : ./.claude/skills/   (project-scoped skills only)"
fi
if [ -d "$GROK_DIR" ] || [ -d "$GROK_SKILLS_DIR" ]; then
    echo "  Grok:"
    echo "    - User profile : ~/.grok/skills/"
    echo "    - This project : ./.grok/skills/     (project-scoped skills only)"
fi
if [ -d "$FACTORY_DIR" ]; then
    echo "  Factory:"
    echo "    - User profile : ~/.factory/skills/"
    echo "    - This project : ./.factory/skills/  (project-scoped skills only)"
fi
if [ -d "$CODEX_DIR" ]; then
    echo "  Codex:"
    echo "    - User profile : ~/.codex/skills/"
    echo "    - This project : ./.codex/skills/  (project-scoped skills only)"
fi
if [ -d "$OPENCODE_CONFIG_DIR" ] || [ -d "${SCRIPT_DIR}/.opencode" ]; then
    echo "  OpenCode:"
    echo "    - Skills (user)    : ~/.config/opencode/skills/"
    echo "    - Skills (project) : .opencode/skills/   (project-scoped only)"
    echo "    - Commands (user)  : ~/.config/opencode/commands/"
    echo "    - Commands (project): .opencode/commands/ (project-scoped only)"
    echo "    Note: OpenCode sub-skills are published both as loadable skills (skill tool)"
    echo "          and as native commands (for direct /name slash triggers)."
fi
echo
echo "  (Most skills → user profile. The 'skills' meta-skill → local project only.)"
