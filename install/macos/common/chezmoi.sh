#!/usr/bin/env bash

set -Eeuox pipefail

function install_chezmoi() {
    if ! command -v chezmoi >/dev/null; then
        brew install chezmoi
    fi
}

function main() {
    install_chezmoi
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
