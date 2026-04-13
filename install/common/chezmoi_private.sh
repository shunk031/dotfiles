#!/usr/bin/env bash

# @file install/common/chezmoi_private.sh
# @brief Initialize the private chezmoi repository.
# @description
#   Bootstraps `shunk031/dotfiles-private` using the dedicated source and
#   config paths under the current user's home directory.

set -Eeuo pipefail

declare -r PRIVATE_DOTFILES_REPO_URL="https://github.com/shunk031/dotfiles-private"
declare -r PRIVATE_DOTFILES_PATH="${HOME}/.local/share/chezmoi-private"
declare -r PRIVATE_DOTFILES_CONFIG_PATH="${HOME}/.config/chezmoi-private/chezmoi.yaml"

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Initialize the private dotfiles repository if it is available.
#
function install_chezmoi_private() {
    if chezmoi init \
        --apply \
        --ssh \
        --source "${PRIVATE_DOTFILES_PATH}" \
        --config "${PRIVATE_DOTFILES_CONFIG_PATH}" \
        "${PRIVATE_DOTFILES_REPO_URL}"; then
        return 0
    fi

    echo "Warning: Failed to initialize dotfiles-private. Skipping private dotfiles setup." >&2
}

#
# @description Remove the private chezmoi source and config paths.
#
function uninstall_chezmoi_private() {
    rm -rfv "${PRIVATE_DOTFILES_PATH}"
    rm -rfv "${PRIVATE_DOTFILES_CONFIG_PATH}"
}

#
# @description Run the private chezmoi initialization flow.
#
function main() {
    install_chezmoi_private
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
