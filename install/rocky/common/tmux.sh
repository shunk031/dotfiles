#!/usr/bin/env bash

# @file install/rocky/common/tmux.sh
# @brief Install tmux on Rocky Linux.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
)

#
# @description Install the Rocky Linux tmux package.
#
function install_tmux() {
    if command -v tmux > /dev/null 2>&1; then
        return 0
    fi

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y "${PACKAGES[@]}"
}

#
# @description Run the Rocky Linux tmux installation flow.
#
function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
