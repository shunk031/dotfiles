#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_ghq() {
    local dir_name="ghq_linux_amd64"
    local zip_name="${dir_name}.zip"

    local url="https://github.com/x-motemen/ghq/releases/latest/download/${zip_name}"

    # create tmp directory
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    # download zip file
    local zip_path="${tmp_dir%/}/${zip_name}"
    wget -qO "${zip_path}" "${url}"

    # unzip the zip file
    unzip -q "${zip_path}" -d "${tmp_dir}"

    # move the binary to the directory
    local local_bin_dir="${HOME%/}/.local/bin"
    mkdir -p "${local_bin_dir}"
    mv -v "${tmp_dir%/}/${dir_name}/ghq" "${local_bin_dir}"

    # clean up the tmp directory
    rm -rf "${tmp_dir}"
}

function uninstall_ghq() {
    rm -f "${HOME%/}/.local/bin/ghq"
}

function main() {
    install_ghq
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
