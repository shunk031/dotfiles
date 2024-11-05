#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_uv() {
    # https://docs.astral.sh/uv/getting-started/installation/#standalone-installer
    curl -LsSf https://github.com/astral-sh/uv/releases/latest/download/uv-installer.sh | sh
}

function uninstall_uv() {
    # https://docs.astral.sh/uv/getting-started/installation/#uninstallation
    uv cache clean
    rm -rf "$(uv python dir)"
    rm -rf "$(uv tool dir)"
    rm -f "${HOME}/.cargo/bin/uv" "${HOME}/.cargo/bin/uvx"
}

function main() {
    install_uv
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
