#!/usr/bin/env zsh

# -----------------------------------------------------------------------------
# chezmoi-notify: Asynchronous update check plugin for chezmoi for Starship
# -----------------------------------------------------------------------------

function _check_chezmoi_update_async() {
    local helper_path="${HOME}/.local/bin/common/chezmoi-notify-cache"

    if [[ -x "${helper_path}" ]]; then
        ("${helper_path}" refresh-if-stale > /dev/null 2>&1) &|
    fi
}

# Register the hook (precmd: executed just before prompt display)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _check_chezmoi_update_async
