#!/usr/bin/env bash

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"

function install_mise() {
    # https://mise.run
    local version="v2025.9.25"
    local url="https://raw.githubusercontent.com/jdx/mise/refs/tags/${version}/packaging/standalone/install.envsubst"
    
    export MISE_CURRENT_VERSION="${version}"
    curl "${url}" | sh
    
}

function install_mise_python() {
    mise use --global python@3.11
}

function install_mise_node() {
    mise use --global node@lts
}

function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

function main() {
    install_mise

    install_mise_python
    install_mise_node
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi


