#!/usr/bin/env bash

set -Eeuox pipefail

function is_homebrew_exists() {
    command -v brew &>/dev/null
}

function install_homebrew() {
    if ! is_homebrew_exists; then
        printf "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

function opt_out_of_analytics() {
    brew analytics off
}

function main() {
    install_homebrew
    opt_out_of_analytics
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
