#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_aqua() {
    # ref. https://aquaproj.github.io/docs/products/aqua-installer#shell-script
    local version=3.1.1

    local url
    url="https://raw.githubusercontent.com/aquaproj/aqua-installer/v${version}/aqua-installer"

    curl -sSfL "${url}" | bash
}

function uninstall_aqua() {
    # ref. https://aquaproj.github.io/docs/reference/uninstall/
    rm /usr/local/bin/aqua
    rm -R ~/.local/share/aquaproj-aqua
}

function main() {
    install_aqua
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
