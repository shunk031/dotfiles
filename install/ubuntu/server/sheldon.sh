#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin/server"

function install_sheldon() {
    mkdir -p "${BIN_DIR}"

    if [[ -n "${DOTFILES_GITHUB_PAT:-}" ]]; then
        export GITHUB_TOKEN=${DOTFILES_GITHUB_PAT}
    fi

    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${BIN_DIR}" --force
}

function uninstall_sheldon() {
    rm "${BIN_DIR}"
}

function main() {
    install_sheldon
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
