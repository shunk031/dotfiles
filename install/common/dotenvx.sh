#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

function install_dotenvx() {
    mkdir -vp "${BIN_DIR}"

    local version="1.51.1"
    local url="https://raw.githubusercontent.com/dotenvx/dotenvx/refs/tags/v${version}/install.sh"
    curl -sfS "${url}" | sh -s -- --directory="${BIN_DIR}" --version="${version}"
}

function uninstall_dotenvx() {
    rm "${BIN_DIR}/dotenvx"
}

function main() {
    install_dotenvx
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
