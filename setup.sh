#!/bin/bash

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define source directories (absolute paths)
SKILLS_SOURCE="${SCRIPT_DIR}/skills"
COMMANDS_SOURCE="${SCRIPT_DIR}/commands"

# Define target directories
CLAUDE_DIR="${HOME}/.claude"
FACTORY_DIR="${HOME}/.factory"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to create a symlink with proper error handling
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

# Main setup
echo "========================================="
echo "Setting up agent-tools symlinks"
echo "========================================="
echo

# Check if source directories exist
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo -e "${RED}Error: Skills directory not found at $SKILLS_SOURCE${NC}"
    echo "Please ensure you're running this script from the agent-tools directory."
    exit 1
fi

if [ ! -d "$COMMANDS_SOURCE" ]; then
    echo -e "${RED}Error: Commands directory not found at $COMMANDS_SOURCE${NC}"
    echo "Please ensure you're running this script from the agent-tools directory."
    exit 1
fi

echo "Source directories:"
echo "  Skills:   $SKILLS_SOURCE"
echo "  Commands: $COMMANDS_SOURCE"
echo

# Create symlinks for ~/.claude
echo "Setting up ~/.claude symlinks..."
create_symlink "$SKILLS_SOURCE" "${CLAUDE_DIR}/skills"
create_symlink "$COMMANDS_SOURCE" "${CLAUDE_DIR}/commands"
echo

# Create symlinks for ~/.factory
echo "Setting up ~/.factory symlinks..."
create_symlink "$SKILLS_SOURCE" "${FACTORY_DIR}/skills"
create_symlink "$COMMANDS_SOURCE" "${FACTORY_DIR}/commands"
echo

echo "========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "========================================="
echo
echo "The following symlinks have been configured:"
echo "  ~/.claude/skills -> $SKILLS_SOURCE"
echo "  ~/.claude/commands -> $COMMANDS_SOURCE"
echo "  ~/.factory/skills -> $SKILLS_SOURCE"
echo "  ~/.factory/commands -> $COMMANDS_SOURCE"