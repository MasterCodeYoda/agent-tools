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
# Note: The skill corpus now lives under src/ (post 2026-05 restructure).
# The meta-skill 'skills' lives at src/skills/ and provides /skills:import and /skills:evolve.

CLAUDE_DIR="${HOME}/.claude"
FACTORY_DIR="${HOME}/.factory"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# ── Factory copy functions ──────────────────────────────────────────

# Sync src/ -> ~/.factory/skills/ using rsync
copy_factory_skills() {
    local skills_dir="$1"
    local target_dir="${FACTORY_DIR}/skills"

    # Transition: if target is an old symlink, remove it so rsync can create a real dir
    if [ -L "$target_dir" ]; then
        rm "$target_dir"
    fi

    mkdir -p "$target_dir"

    rsync -a --delete \
        --exclude='node_modules/' \
        --exclude='.DS_Store' \
        "${skills_dir}/" "${target_dir}/"

    if [ "$FACTORY_ONLY" = false ]; then
        echo -e "${GREEN}✓${NC} Synced skills to ${target_dir}"
    fi
}

# Orchestrator: copy skills to Factory
copy_to_factory() {
    # Transition: remove old symlinks at top level before copy
    if [ -L "${FACTORY_DIR}/commands" ]; then
        rm "${FACTORY_DIR}/commands"
    fi
    if [ -L "${FACTORY_DIR}/skills" ]; then
        rm "${FACTORY_DIR}/skills"
    fi

    copy_factory_skills "$SKILLS_SOURCE"
}

# ── Claude symlink setup ───────────────────────────────────────────

setup_claude() {
    echo "Setting up ~/.claude symlinks..."
    create_symlink "$SKILLS_SOURCE" "${CLAUDE_DIR}/skills"
    # Note: All skills (including the meta-skill) now live under src/. No separate commands symlink.
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
    # COMMANDS_SOURCE check removed — commands/ has been migrated into src/
}

if [ "$FACTORY_ONLY" = true ]; then
    # Fast path: just copy factory files, no output
    validate_sources
    copy_to_factory
else
    # Full setup
    validate_sources

    echo "========================================="
    echo "Setting up agent-tools"
    echo "========================================="
    echo
    echo "Source directories:"
    echo "  Skills:   $SKILLS_SOURCE (all skills, including the 'skills' meta-skill)"
    echo

    setup_claude
    copy_to_factory

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
    echo "Configured:"
    echo "  ~/.claude/skills   -> $SKILLS_SOURCE (symlink)"
    echo "  ~/.factory/skills  -> copied from $SKILLS_SOURCE"
    echo "  (All skills, including the 'skills' meta-skill, now live under src/)"
fi
