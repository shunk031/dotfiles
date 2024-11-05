#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_uv() {
    # https://docs.astral.sh/uv/getting-started/installation/#standalone-installer
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

function uninstall_uv() {
    # https://docs.astral.sh/uv/getting-started/installation/#uninstallation
    uv cache clean
    rm -r "$(uv python dir)"
    rm -r "$(uv tool dir)"

    rm "${HOME}/.cargo/bin/uv" "${HOME}/.cargo/bin/uvx"
}

function main() {
    install_rust
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
