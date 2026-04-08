#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

readonly GH_EXTENSIONS=(
    seachicken/gh-poi
)

function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

function install_gh_extensions() {
    for extension in "${GH_EXTENSIONS[@]}"; do
        gh extension install "${extension}"
    done
}

function main() {
    activate_mise
    install_gh_extensions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
