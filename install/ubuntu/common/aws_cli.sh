#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_awscli() {
    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/awscli-XXXXXXXXXX)"
    cd "${tmp_dir}" || exit 1

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --update

    rm -rf "${tmp_dir}"
}

function uninstall_awscli() {
    sudo rm -rf /usr/local/aws-cli
}

function main() {
    install_awscli
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
