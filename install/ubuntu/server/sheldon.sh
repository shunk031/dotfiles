#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly bin_dir="${HOME}/.local/bin/server"

function install_sheldon() {
    mkdir -p "${bin_dir}"

    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${bin_dir}"
}

function uninstall_sheldon() {
    rm "${bin_dir}"
}

function main() {
    install_sheldon
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
