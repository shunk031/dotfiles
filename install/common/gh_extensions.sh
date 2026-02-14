#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly GH_EXTENSIONS=(
    seachicken/gh-poi
)

function install_gh_extensions() {
    for extension in "${GH_EXTENSIONS[@]}"; do
        gh extension install "${extension}"
    done
}

function main() {
    install_gh_extensions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
