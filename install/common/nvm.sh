#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function get_latest_nvm_version() {
    local latest_release_url="https://api.github.com/repos/nvm-sh/nvm/releases/latest"
    local latest_version

    if command -v curl &> /dev/null; then
        if [ -n "${DOTFILES_GITHUB_PAT:-}" ]; then
            latest_version=$(curl -s --header "Authorization: Bearer ${DOTFILES_GITHUB_PAT}" "${latest_release_url}" | jq -r '.tag_name')
        else
            latest_version=$(curl -s "${latest_release_url}" | jq -r '.tag_name')
        fi
    elif command -v wget &> /dev/null; then
        if [ -n "${DOTFILES_GITHUB_PAT:-}" ]; then
            latest_version=$(wget -qO- --header="Authorization: Bearer ${DOTFILES_GITHUB_PAT}" "${latest_release_url}" | jq -r '.tag_name')
        else
            latest_version=$(wget -qO- "${latest_release_url}" | jq -r '.tag_name')
        fi
    else
        echo "Error: Neither curl nor wget is installed."
        return 1
    fi

    echo "${latest_version}"
}

function install_nvm() {
    local latest_release_url="https://api.github.com/repos/nvm-sh/nvm/releases/latest"
    
    local latest_version
    latest_version=$(get_latest_nvm_version)

    if command -v curl &> /dev/null; then
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_version}/install.sh" | bash
    elif command -v wget &> /dev/null; then
        wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_version}/install.sh" | bash
    else
        echo "Error: Neither curl nor wget is installed."
        return 1
    fi
}

function uninstall_nvm() {
    rm -rfv "${HOME}/.nvm"
}

function main() {
    install_nvm
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
