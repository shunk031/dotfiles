#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_git_credential_manager() {
    local gcm_version="2.6.0"
    local gcm_deb="gcm-linux_amd64.${gcm_version}.deb"
    wget "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${gcm_version}/${gcm_deb}"
    sudo dpkg -i ${gcm_deb}
    rm -v ${gcm_deb}
    git-credential-manager configure
}

function uninstall_git_credential_manager() {
    git-credential-manager unconfigure
    sudo dpkg -r gcm
}

function main() {
    install_git_credential_manager
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
