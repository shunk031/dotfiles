#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_INSTALL_PATH="${HOME}/.local/bin/mise"

function install_mise() {
    mkdir -p "${BIN_DIR}"

    if [[ -n "${DOTFILES_GITHUB_PAT:-}" ]]; then
        export GITHUB_TOKEN=${DOTFILES_GITHUB_PAT}
    fi
    
    # https://mise.run
    local version="v2025.9.25"
    local url="https://raw.githubusercontent.com/jdx/mise/refs/tags/${version}/packaging/standalone/install.envsubst"

    export "${MISE_INSTALL_PATH}"
    curl "${url}" | sh
}

function uninstall_mise() {
    rm "${BIN_DIR}/mise"
}

function main() {
    install_mise
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi


