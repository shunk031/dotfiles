#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin/server"

function install_starship() {
    mkdir -p "${BIN_DIR}"

    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "${BIN_DIR}"
}

function uninstall_starship() {
    rm -rf "${BIN_DIR}"
}

function main() {
    install_starship
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
