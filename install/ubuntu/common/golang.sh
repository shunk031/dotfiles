#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function get_latest_version() {
    local version
    version="$(curl https://go.dev/VERSION?m=text | head -n 1)"
    echo "${version}"
}

function install_golang() {

    if [ -d "/usr/local/go" ]; then
        sudo rm -rfv "/usr/local/go"
    fi

    local tmp_file
    tmp_file="$(mktemp /tmp/golang-XXXXXXXXXX)"

    curl -fSL "https://go.dev/dl/$(get_latest_version).linux-amd64.tar.gz" -o "${tmp_file}"
    sudo tar -C /usr/local -xzf "${tmp_file}"

    rm -f "${tmp_file}"
}

function uninstall_golang() {
    sudo rm -rfv /usr/local/go
}

function main() {
    install_golang
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
