#!/usr/bin/env bash
# Favorite Commands System - Installer
# Add source line to .bashrc / .zshrc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FC_SCRIPT="$SCRIPT_DIR/favorite_cmds.sh"
SOURCE_LINE="source \"$FC_SCRIPT\""

add_to_rc() {
    local rc="$1"
    if [[ -f "$rc" ]]; then
        if ! grep -qF "$FC_SCRIPT" "$rc"; then
            echo "" >> "$rc"
            echo "# Favorite Commands System" >> "$rc"
            echo "$SOURCE_LINE" >> "$rc"
            echo "  Added to $rc"
        else
            echo "  Already in $rc, skipped"
        fi
    fi
}

if [[ -n "$BASH_VERSION" ]] || [[ -f "$HOME/.bashrc" ]]; then
    add_to_rc "$HOME/.bashrc"
fi
if [[ -n "$ZSH_VERSION" ]] || [[ -f "$HOME/.zshrc" ]]; then
    add_to_rc "$HOME/.zshrc"
fi

echo ""
echo "Done. Restart terminal or run:"
echo "  source $FC_SCRIPT"
