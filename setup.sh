#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ────────────────────────────────────────────────
FACTORY_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --factory-only) FACTORY_ONLY=true ;;
        --help|-h)
            echo "Usage: setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --factory-only   Only copy skills to ~/.factory (no symlinks, no banners)"
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

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Marker file placed inside every skill installed by this repo.
# Used to safely identify and prune stale skills on future runs.
MANAGED_MARKER=".agent-tools"

# ── Helpers ─────────────────────────────────────────────────────────

# Create a symlink with proper error handling (used for ~/.claude only)
create_symlink() {
    local source="$1"
    local target="$2"
    local parent_dir="$(dirname "$target")"

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

# Install a single skill directory for a given agent
install_skill() {
    local agent="$1"               # claude, grok, factory
    local skill_name="$2"          # e.g. "workflow", "skills"
    local source_skill_dir="$3"    # e.g. dist/claude/skills/workflow

    local target_base
    local publish_target
    publish_target=$(get_publish_target "$source_skill_dir")

    local target_base
    local scope_label

    local target_base
    local scope_label
    local created_local_dir=false

    if [ "$publish_target" = "project" ]; then
        target_base="${SCRIPT_DIR}/.${agent}/skills"
        scope_label="${YELLOW}[project]${NC}"

        if [ ! -d "$target_base" ]; then
            mkdir -p "$target_base"
            echo -e "  ${YELLOW}→${NC} Created local project directory: .${agent}/skills/ (for project-scoped skills)"
        fi
    else
        target_base="${HOME}/.${agent}/skills"
        scope_label="[user]"
    fi

    local target="${target_base}/${skill_name}"

    # Print clean one-line status
    if [ "$agent" = "factory" ]; then
        echo -e "  ${scope_label} ${skill_name}  (copied to)  ${target}"
    else
        echo -e "  ${scope_label} ${skill_name}  →  ${target}"
    fi

    mkdir -p "$(dirname "$target")"

    if [ "$agent" = "factory" ]; then
        mkdir -p "$target_base"
        rsync -a --delete "${source_skill_dir}/" "${target}/" 2>/dev/null || rsync -a "${source_skill_dir}/" "${target}/"
    else
        # Symlink, replacing if needed (non-interactive for normal setup flow)
        ln -sfn "$source_skill_dir" "$target"
    fi

    # Mark this skill as managed by agent-tools so future runs can safely prune it if removed.
    touch "${target}/${MANAGED_MARKER}"
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
        [ -e "$entry" ] || continue
        local name
        name=$(basename "$entry")

        # Only consider directories or symlinks that look like skills
        if [ -d "$entry" ] || [ -L "$entry" ]; then
            local marker="${entry}/${MANAGED_MARKER}"
            if [ -e "$marker" ]; then
                # Check if still published
                local still_published=false
                for pub in "${current_published[@]}"; do
                    if [ "$pub" = "$name" ]; then
                        still_published=true
                        break
                    fi
                done

                if [ "$still_published" = false ]; then
                    echo -e "  ${YELLOW}→${NC} Removing stale managed skill: ${name}"
                    rm -rf "$entry"
                    ((removed++))
                fi
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
    if [ "$agent" != "factory" ]; then
        local user_skills_dir="${HOME}/.${agent}/skills"
        if [ -L "$user_skills_dir" ]; then
            echo -e "${YELLOW}⚠${NC}  Replacing legacy whole-skills symlink: ${user_skills_dir} (migrating to per-skill layout)"
            rm -f "$user_skills_dir"
        fi
    fi

    for skill_dir in "${dist_agent_dir}"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name=$(basename "$skill_dir")

        install_skill "$agent" "$skill_name" "$skill_dir"
    done

    # Prune any previously managed skills that are no longer published.
    # This safely removes old entries (including legacy flat skills and
    # any renamed/removed grouped or flattened skills) without touching
    # third-party skills.
    local user_target="${HOME}/.${agent}/skills"
    local project_target="${SCRIPT_DIR}/.${agent}/skills"

    prune_stale_skills "$agent" "$user_target" "$dist_agent_dir"
    prune_stale_skills "$agent" "$project_target" "$dist_agent_dir"

    echo
}

# ── Droid shell function injection ──────────────────────────────────

setup_droid_function() {
    local marker="# agent-tools: droid wrapper"
    local zshrc="${HOME}/.zshrc"

    if grep -qF "$marker" "$zshrc" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Droid wrapper already in ~/.zshrc"
        return
    fi

    cat >> "$zshrc" <<'DROID_EOF'

# agent-tools: droid wrapper
droid() {
    AGENT_TOOLS_DIR="${AGENT_TOOLS_DIR:-$HOME/Source/OMG/agent-tools}"
    if [ -f "$AGENT_TOOLS_DIR/setup.sh" ]; then
        "$AGENT_TOOLS_DIR/setup.sh" --factory-only
    fi
    command droid "$@"
}
DROID_EOF

    echo -e "${GREEN}✓${NC} Added droid wrapper function to ~/.zshrc"
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

    echo "Publishing skills for all agents (claude, grok, factory)..."
    if "$publisher" --quiet; then
        echo -e "${GREEN}✓${NC} Publishing complete → dist/<agent>/skills/"
    else
        echo -e "${RED}✗${NC} Publishing failed. Aborting setup." >&2
        exit 1
    fi
    echo
}

if [ "$FACTORY_ONLY" = true ]; then
    # Fast path: publish + copy only for Factory
    validate_sources
    run_publisher

    echo "Factory-only mode: installing skills for factory..."
    install_skills_for_agent "factory"

    echo -e "${GREEN}✓${NC} Factory setup complete (using dist/factory/skills/)"
else
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

    # Clean up legacy factory-commands/ directory in the repo
    if [ -d "${SCRIPT_DIR}/factory-commands" ]; then
        rm -rf "${SCRIPT_DIR}/factory-commands"
        echo -e "${GREEN}✓${NC} Removed legacy factory-commands/ directory"
    fi

    setup_droid_function
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
    echo
    echo "  (Most skills → user profile. The 'skills' meta-skill → local project only.)"
fi
