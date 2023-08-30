#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin/server"
readonly GITHUB_TOKEN="${GITHUB_TOKEN:-}"

function install_sheldon() {
    mkdir -p "${BIN_DIR}"

    if [[ -n "${GITHUB_TOKEN}" ]]; then
        export GITHUB_TOKEN
    fi

    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${BIN_DIR}"
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
