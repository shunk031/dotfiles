#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_jq_installed() {
    command -v jq &>/dev/null
}

function get_latest_version() {
    curl -s https://api.github.com/repos/ogham/exa/releases/latest | jq -r '.tag_name'
}

function install_exa() {
    local version
    version=$(get_latest_version)

    local zip_name="exa-linux-x86_64-${version}.zip"
    local url="https://github.com/ogham/exa/releases/download/${version}/${zip_name}"

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
    mv -v "${tmp_dir%/}/bin/exa" "${local_bin_dir}"

    # clean up the tmp directory
    rm -rf "${tmp_dir}"
}

function install_jq() {
    if ! is_jq_installed; then
        sudo apt-get install -y jq
    fi
}

function uninstall_exa() {
    rm -v "${HOME%/}/.local/bin/exa"
}

function uninstall_jq() {
    sudo apt-get remove -y jq
}

function main() {
    install_jq
    install_exa
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
