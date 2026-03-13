#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DEST="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE_CONFIG='{"statusLine":{"type":"command","command":"~/.claude/statusline.sh"}}'

# ── Helpers ─────────────────────────────────────────────
info()  { printf "\033[36m%s\033[0m\n" "$1"; }
ok()    { printf "\033[32m✔ %s\033[0m\n" "$1"; }
warn()  { printf "\033[33m⚠ %s\033[0m\n" "$1"; }
err()   { printf "\033[31m✖ %s\033[0m\n" "$1" >&2; }

check_deps() {
    local missing=()
    for cmd in jq curl git; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        err "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# ── Install ─────────────────────────────────────────────
do_install() {
    check_deps
    mkdir -p "$CLAUDE_DIR"

    # Back up existing statusline script if present
    if [ -f "$DEST" ]; then
        local backup="$DEST.bak.$(date +%s)"
        cp "$DEST" "$backup"
        warn "Existing statusline backed up to $backup"
    fi

    # Copy script
    cp "$SCRIPT_DIR/statusline.sh" "$DEST"
    chmod 755 "$DEST"
    ok "Installed statusline.sh to $DEST"

    # Merge statusLine config into settings.json
    if [ -f "$SETTINGS" ]; then
        local merged
        merged=$(jq --argjson new "$STATUSLINE_CONFIG" '. * $new' "$SETTINGS")
        echo "$merged" > "$SETTINGS"
    else
        echo "$STATUSLINE_CONFIG" | jq . > "$SETTINGS"
    fi
    ok "Updated $SETTINGS with statusLine config"

    info ""
    info "Restart Claude Code to see the new status line."
}

# ── Uninstall ───────────────────────────────────────────
do_uninstall() {
    if [ -f "$DEST" ]; then
        rm "$DEST"
        ok "Removed $DEST"
    else
        warn "No statusline.sh found at $DEST"
    fi

    if [ -f "$SETTINGS" ]; then
        local updated
        updated=$(jq 'del(.statusLine)' "$SETTINGS")
        echo "$updated" > "$SETTINGS"
        ok "Removed statusLine key from $SETTINGS"
    fi

    info ""
    info "Restart Claude Code to apply changes."
}

# ── Main ────────────────────────────────────────────────
case "${1:-}" in
    --uninstall)
        do_uninstall
        ;;
    *)
        do_install
        ;;
esac
