#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    busybox
    cmake
    curl
    git
    gpg
    htop
    iproute2
    iputils-ping
    sudo
    unzip
    vim
    wget
    zsh
)

function run_apt_get() {
    if ! command -v sudo > /dev/null 2>&1; then
        apt-get update
        apt-get install -y sudo
    fi

    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get "$@"
}

function install_apt_packages() {
    local missing_packages=()
    local package

    for package in "${PACKAGES[@]}"; do
        if ! command -v "${package}" > /dev/null 2>&1; then
            missing_packages+=("${package}")
        fi
    done

    if [ "${#missing_packages[@]}" -eq 0 ]; then
        return 0
    fi

    run_apt_get install -y "${missing_packages[@]}"
}

function uninstall_apt_packages() {
    local removable_packages=()
    local package

    for package in "${PACKAGES[@]}"; do
        if [ "${package}" != "sudo" ] && [ "${package}" != "git" ]; then
            removable_packages+=("${package}")
        fi
    done

    if [ "${#removable_packages[@]}" -eq 0 ]; then
        return 0
    fi

    run_apt_get remove -y "${removable_packages[@]}"
}

function main() {
    install_apt_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
