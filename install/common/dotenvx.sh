#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_dotenvx() {
    local version="1.51.1"
    local url="https://raw.githubusercontent.com/dotenvx/dotenvx/refs/tags/v${version}/install.sh"
    curl -sfS "${url}?directory=${HOME}/.local/bin&version=${version}" | sh
}

function main() {
    install_dotenvx
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
