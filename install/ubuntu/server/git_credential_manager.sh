#!/usr/bin/env bash

# @file install/ubuntu/server/git_credential_manager.sh
# @brief Git Credential Manager installation script
# @description
#   This script installs Git Credential Manager (GCM), a secure credential
#   helper for Git that supports multiple authentication methods including
#   OAuth and personal access tokens.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Download and install Git Credential Manager
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_git_credential_manager
function install_git_credential_manager() {
    local gcm_version="2.6.0"
    local gcm_deb="gcm-linux_amd64.${gcm_version}.deb"
    wget "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${gcm_version}/${gcm_deb}"
    sudo dpkg -i ${gcm_deb}
    rm -v ${gcm_deb}
    git-credential-manager configure
}

# @description Uninstall Git Credential Manager
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_git_credential_manager
function uninstall_git_credential_manager() {
    git-credential-manager unconfigure
    sudo dpkg -r gcm
}

# @description Main entry point for Git Credential Manager installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./git_credential_manager.sh
function main() {
    install_git_credential_manager
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
