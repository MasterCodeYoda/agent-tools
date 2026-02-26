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
            echo "  --factory-only   Only copy commands/skills to ~/.factory (no symlinks, no banners)"
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
SKILLS_SOURCE="${SCRIPT_DIR}/skills"
COMMANDS_SOURCE="${SCRIPT_DIR}/commands"

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

# Copy flattened commands into ~/.factory/commands/
# Factory doesn't support folder namespacing, so we flatten:
#   commands/git/commit.md  ->  ~/.factory/commands/git-commit.md
copy_factory_commands() {
    local commands_dir="$1"
    local target_dir="${FACTORY_DIR}/commands"

    # Clean slate: remove old files, recreate directory
    rm -rf "$target_dir"
    mkdir -p "$target_dir"

    local count=0

    # Find all subfolders in commands (1 level deep)
    for subfolder in "$commands_dir"/*/; do
        [ -d "$subfolder" ] || continue

        local folder_name=$(basename "$subfolder")

        # Copy all .md files, flattening the namespace
        for file in "$subfolder"*.md; do
            [ -f "$file" ] || continue

            local file_name=$(basename "$file")
            local target_name="${folder_name}-${file_name}"

            cp "$file" "${target_dir}/${target_name}"
            count=$((count + 1))
        done
    done

    if [ "$FACTORY_ONLY" = false ]; then
        echo -e "${GREEN}✓${NC} Copied ${count} commands to ${target_dir}"
    fi
}

# Sync skills/ -> ~/.factory/skills/ using rsync
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

# Orchestrator: handle legacy symlinks, then copy both
copy_to_factory() {
    # Transition: remove old symlinks at top level before copy functions run
    if [ -L "${FACTORY_DIR}/commands" ]; then
        rm "${FACTORY_DIR}/commands"
    fi
    if [ -L "${FACTORY_DIR}/skills" ]; then
        rm "${FACTORY_DIR}/skills"
    fi

    copy_factory_commands "$COMMANDS_SOURCE"
    copy_factory_skills "$SKILLS_SOURCE"
}

# ── Claude symlink setup ───────────────────────────────────────────

setup_claude() {
    echo "Setting up ~/.claude symlinks..."
    create_symlink "$SKILLS_SOURCE" "${CLAUDE_DIR}/skills"
    create_symlink "$COMMANDS_SOURCE" "${CLAUDE_DIR}/commands"
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
    if [ ! -d "$COMMANDS_SOURCE" ]; then
        echo -e "${RED}Error: Commands directory not found at $COMMANDS_SOURCE${NC}" >&2
        exit 1
    fi
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
    echo "  Skills:   $SKILLS_SOURCE"
    echo "  Commands: $COMMANDS_SOURCE"
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
    echo "  ~/.claude/commands -> $COMMANDS_SOURCE (symlink)"
    echo "  ~/.factory/skills  -> copied from $SKILLS_SOURCE"
    echo "  ~/.factory/commands -> flattened from $COMMANDS_SOURCE"
fi
