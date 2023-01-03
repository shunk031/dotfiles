#!/usr/bin/env bash

set -Eeuox pipefail

function get_latest_version() {
    local version
    version="$(curl https://go.dev/VERSION?m=text)"
    echo "${version}"
}

function install_golang() {
    local tmp_file
    tmp_file="$(mktemp /tmp/golang-XXXXXXXXXX)"

    curl -fSL "https://go.dev/dl/$(get_latest_version).linux-amd64.tar.gz" -o "${tmp_file}"
    sudo tar -C /usr/local -xzf "${tmp_file}"

    rm -f "${tmp_file}"
}

function main() {
    install_golang
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
