#!/usr/bin/env bash
# Favorite Commands System
# Press Ctrl+/ to bring up fzf command list, select to fill into command line

FAVORITE_CMDS_DIR="${FAVORITE_CMDS_DIR:-$HOME/favorite_cmds}"

_fc_load_local() {
    local file="$FAVORITE_CMDS_DIR/local"
    [[ -f "$file" ]] || return
    local cwd matched=0 has_output=0 match_dir=""
    cwd="$(pwd)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == \#* ]]; then
            local dir="${line#\#}"
            dir="${dir#"${dir%%[![:space:]]*}"}"
            dir="${dir%"${dir##*[![:space:]]}"}"
            if [[ "$cwd" == "$dir" || "$cwd" == "$dir"/* ]]; then
                matched=1
                match_dir="$dir"
            else
                matched=0
            fi
        elif [[ $matched -eq 1 ]]; then
            if [[ $has_output -eq 0 ]]; then
                echo -e "\033[33m── Local ($match_dir) ──\033[0m"
                has_output=1
            fi
            echo "$line"
        fi
    done < "$file"
}

_fc_load_global() {
    local file="$FAVORITE_CMDS_DIR/global"
    if [[ -f "$file" ]]; then
        echo -e "\033[33m── Global ──\033[0m"
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            if [[ "$line" == \#* ]]; then
                echo -e "\033[36m$line\033[0m"
            else
                echo "$line"
            fi
        done < "$file"
    fi
}

_fc_load_tools() {
    local tools_dir="$FAVORITE_CMDS_DIR/tools"
    [[ -d "$tools_dir" ]] || return
    local has_tools=0
    for f in "$tools_dir"/*; do
        [[ -f "$f" ]] || continue
        if [[ $has_tools -eq 0 ]]; then
            echo -e "\033[33m── Tools ──\033[0m"
            has_tools=1
        fi
        local name
        name=$(basename "$f")
        echo -e "\033[35m# [$name]\033[0m"
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            if [[ "$line" == \#* ]]; then
                echo -e "\033[36m$line\033[0m"
            else
                echo "$line"
            fi
        done < "$f"
    done
}

fzf_favorite_cmds() {
    local cmd
    cmd=$( { _fc_load_local; _fc_load_global; _fc_load_tools; } \
        | fzf --ansi --height 40% --reverse \
              --prompt="⭐ Favorites> " \
              --header="Ctrl+/  |  Enter=select  Esc=cancel" \
              --header-first )

    [[ -z "$cmd" ]] && return

    local clean
    clean=$(echo "$cmd" | sed 's/\x1b\[[0-9;]*m//g')
    [[ "$clean" == \#* ]] && return
    [[ "$clean" == ──* ]] && return

    if [[ -n "${READLINE_LINE+x}" ]]; then
        READLINE_LINE="${READLINE_LINE}${clean}"
        READLINE_POINT=${#READLINE_LINE}
    else
        print -z "$clean" 2>/dev/null || echo "$clean"
    fi
}

_fc_init() {
    mkdir -p "$FAVORITE_CMDS_DIR/tools"
    [[ -f "$FAVORITE_CMDS_DIR/global" ]] || touch "$FAVORITE_CMDS_DIR/global"
    [[ -f "$FAVORITE_CMDS_DIR/local" ]] || touch "$FAVORITE_CMDS_DIR/local"
    echo "favorite_cmds: initialized -> $FAVORITE_CMDS_DIR"
}

fc_add() {
    local target="${1:-local}"
    local cmd="$2"
    if [[ -z "$cmd" ]]; then
        echo "Usage: fc_add <local|global|tool:name> <command>"
        return 1
    fi
    case "$target" in
        local)
            local file="$FAVORITE_CMDS_DIR/local"
            local cwd header found=0
            cwd="$(pwd)"
            header="# $cwd"
            [[ -f "$file" ]] || touch "$file"
            while IFS= read -r line; do
                if [[ "$line" == "$header" ]]; then
                    found=1; break
                fi
            done < "$file"
            if [[ $found -eq 0 ]]; then
                echo "" >> "$file"
                echo "$header" >> "$file"
            fi
            echo "$cmd" >> "$file"
            echo "Added to local ($cwd): $cmd"
            ;;
        global)
            echo "$cmd" >> "$FAVORITE_CMDS_DIR/global"
            echo "Added to global: $cmd"
            ;;
        tool:*)
            local name="${target#tool:}"
            echo "$cmd" >> "$FAVORITE_CMDS_DIR/tools/$name"
            echo "Added to tools/$name: $cmd"
            ;;
        *)
            echo "Unknown target: $target (options: local, global, tool:<name>)"
            return 1
            ;;
    esac
}

fc_edit() {
    local target="${1:-local}"
    local editor="${EDITOR:-vi}"
    case "$target" in
        local)  $editor "$FAVORITE_CMDS_DIR/local" ;;
        global) $editor "$FAVORITE_CMDS_DIR/global" ;;
        tool:*) $editor "$FAVORITE_CMDS_DIR/tools/${target#tool:}" ;;
        *)      echo "Unknown target: $target" ; return 1 ;;
    esac
}

if [[ -n "$BASH_VERSION" ]]; then
    bind -x '"\C-_": fzf_favorite_cmds'
elif [[ -n "$ZSH_VERSION" ]]; then
    _fc_zsh_widget() {
        local cmd
        cmd=$( { _fc_load_local; _fc_load_global; _fc_load_tools; } \
            | fzf --ansi --height 40% --reverse \
                  --prompt="⭐ Favorites> " \
                  --header="Ctrl+/  |  Enter=select  Esc=cancel" \
                  --header-first )
        [[ -z "$cmd" ]] && { zle redisplay; return; }
        local clean
        clean=$(echo "$cmd" | sed 's/\x1b\[[0-9;]*m//g')
        [[ "$clean" == \#* ]] && { zle redisplay; return; }
        [[ "$clean" == ──* ]] && { zle redisplay; return; }
        LBUFFER="${LBUFFER}${clean}"
        zle redisplay
    }
    zle -N _fc_zsh_widget
    bindkey '^_' _fc_zsh_widget
fi
