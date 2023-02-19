#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_rust() {
    # Install rust using rustup
    # ref. https://www.rust-lang.org/tools/install
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
}

function uninstall_rust() {
    rustup self uninstall
}

function main() {
    install_rust
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
