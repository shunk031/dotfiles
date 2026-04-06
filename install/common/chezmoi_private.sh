#!/usr/bin/env bash

set -Eeuo pipefail

declare -r PRIVATE_DOTFILES_REPO_URL="https://github.com/shunk031/dotfiles-private"
declare -r PRIVATE_DOTFILES_PATH="${HOME}/.local/share/chezmoi-private"
declare -r PRIVATE_DOTFILES_CONFIG_PATH="${HOME}/.config/chezmoi-private/chezmoi.yaml"

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_chezmoi_private() {
    chezmoi init \
        --apply \
        --ssh \
        --source "${PRIVATE_DOTFILES_PATH}" \
        --config "${PRIVATE_DOTFILES_CONFIG_PATH}" \
        "${PRIVATE_DOTFILES_REPO_URL}"
}

function uninstall_chezmoi_private() {
    rm -rfv "${PRIVATE_DOTFILES_PATH}"
    rm -rfv "${PRIVATE_DOTFILES_CONFIG_PATH}"
}

function main() {
    install_chezmoi_private
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
