#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_jq_installed() {
    command -v jq &>/dev/null
}

function get_latest_version() {
    local url="https://api.github.com/repos/FiloSottile/age/releases/latest"

    local user_opt
    if [[ -n "${DOTFILES_GITHUB_PAT}" ]]; then
        user_opt="-u Saki-htr:${DOTFILES_GITHUB_PAT}"
    else
        user_opt=""
    fi

    curl "${user_opt}" -s "${url}" | jq -r '.tag_name'
}

function install_age() {
    local version
    version=$(get_latest_version)

    local dir_name="age"
    local tar_name="${dir_name}-${version}-linux-amd64.tar.gz"

    local url="https://github.com/FiloSottile/age/releases/download/${version}/age-${version}-linux-amd64.tar.gz"

    # create tmp directory
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    # download tar.gz file
    local tar_path="${tmp_dir%/}/${tar_name}"
    wget -qO "${tar_path}" "${url}"

    # decompress the tar.gz file
    tar -xzf "${tar_path}" -C "${tmp_dir}"

    # move the binary to the directory
    local local_bin_dir="${HOME%/}/.local/bin"
    mkdir -p "${local_bin_dir}"
    mv -v "${tmp_dir%/}/${dir_name}/age" "${local_bin_dir}"

    # clean up the tmp directory
    rm -rf "${tmp_dir}"
}

function install_jq() {
    if ! is_jq_installed; then
        sudo apt-get install -y jq
    fi
}

function uninstall_age() {
    rm -v "${HOME%/}/.local/bin/age"
}

function uninstall_jq() {
    sudo apt-get remove -y jq
}

function main() {
    install_jq
    install_age
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
