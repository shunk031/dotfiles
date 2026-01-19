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

    eval "$(~/.local/bin/mise activate bash)"
}

function run_mise_install() {
    mise install
}

function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

function main() {
    install_mise
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi


