#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_rosetta() {
    local rosetta_path="/Library/Apple/usr/share/rosetta/rosetta"
    if ! [[ -f "${rosetta_path}" ]]; then
        softwareupdate --install-rosetta --agree-to-license
    fi
}

function main() {
    install_rosetta
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
