#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_starship() {
    local bin_dir=${HOME}/.local/bin/server
    mkdir -p "${bin_dir}"

    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "${bin_dir}"
}

function uninstall_starship() {
    sh -c 'rm "$(command -v 'starship')"'
}

function main() {
    install_starship
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
