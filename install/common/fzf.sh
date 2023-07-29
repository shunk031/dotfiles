#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly FZF_DIR="${HOME%/}/.fzf"
readonly FZF_URL="https://github.com/junegunn/fzf.git"

function clone_fzf() {
    if [ ! -d "${FZF_DIR}" ]; then
        git clone "${FZF_URL}" "${FZF_DIR}"
    fi
}

function install_fzf() {
    local install_fzf_path="${FZF_DIR%/}/install"

    "${install_fzf_path}" --bin
}

function uninstall_fzf() {
    local uninstall_fzf_path="${FZF_DIR%/}/uninstall"
    "${uninstall_fzf_path}"

    rm -rfv "${FZF_DIR}"
}

function main() {
    clone_fzf
    install_fzf
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
