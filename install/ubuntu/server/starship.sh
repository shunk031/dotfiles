#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

function install_starship() {
    # equivalent to `https://starship.rs/install.sh`
    local url="https://raw.githubusercontent.com/starship/starship/master/install/install.sh"
    local version="latest"

    mkdir -p "${BIN_DIR}"

    curl -sS "${url}" | dash -s -- \
        --yes \
        --version "${version}" \
        --bin-dir "${BIN_DIR}"
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
