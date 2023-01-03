#!/usr/bin/env bash

set -Eeuox pipefail

function clone_fzf() {
    local fzf_dir="$1"
    local fzf_url="$2"

    if [ ! -d "${fzf_dir}" ]; then
        git clone "${fzf_url}" "${fzf_dir}"
    fi
}

function install_fzf() {
    local fzf_dir="$1"
    local install_fzf_path="${fzf_dir%/}/install"

    "${install_fzf_path}" --key-bindings --completion --no-update-rc
}

function uninstall_fzf() {
    local fzf_dir="${HOME%/}/.fzf"
    local uninstall_fzf_path="${fzf_dir%/}/uninstall"

    "${uninstall_fzf_path}"
}

function main() {
    local fzf_dir="${HOME%/}/.fzf"
    local fzf_url="https://github.com/junegunn/fzf.git"

    clone_fzf "${fzf_dir}" "${fzf_url}"
    install_fzf "${fzf_dir}"
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
