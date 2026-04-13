#!/usr/bin/env bash

# @file install/ubuntu/common/tmux.sh
# @brief Install tmux on Ubuntu.
# @description
#   Installs or removes the Ubuntu `tmux` package while preserving proxy
#   environment variables.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    tmux
)

#
# @description Install the Ubuntu `tmux` package.
#
function install_tmux() {
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y "${PACKAGES[@]}"
}

#
# @description Remove the Ubuntu `tmux` package.
#
function uninstall_tmux() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

#
# @description Run the Ubuntu tmux installation flow.
#
function main() {
    install_tmux
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
