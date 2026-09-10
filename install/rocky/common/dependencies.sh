#!/usr/bin/env bash

# @file install/rocky/common/dependencies.sh
# @brief Install essential Rocky Linux packages.
# @description
#   Maps required commands to Rocky Linux package names and installs only the
#   packages whose commands are missing.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly COMMAND_PACKAGES=(
    "cmp:diffutils"
    "cmake:cmake"
    "curl:curl"
    "git:git"
    "gpg:gnupg2"
    "pinentry-curses:pinentry"
    "htop:htop"
    "ip:iproute"
    "ping:iputils"
    "sudo:sudo"
    "unzip:unzip"
    "vim:vim-enhanced"
    "wget:wget"
    "zsh:zsh"
)

#
# @description Run DNF as root or through sudo while preserving proxy variables.
# @arg $@ string Arguments passed to DNF.
#
function run_dnf() {
    if [ "${EUID}" -eq 0 ]; then
        dnf "$@"
        return
    fi

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf "$@"
}

#
# @description Install packages for commands that are not currently available.
#
function install_dnf_packages() {
    local command_package command_name package_name
    local missing_packages=()

    for command_package in "${COMMAND_PACKAGES[@]}"; do
        command_name="${command_package%%:*}"
        package_name="${command_package#*:}"
        if ! command -v "${command_name}" > /dev/null 2>&1; then
            missing_packages+=("${package_name}")
        fi
    done

    if [ "${#missing_packages[@]}" -eq 0 ]; then
        return 0
    fi

    run_dnf install -y "${missing_packages[@]}"
}

#
# @description Install the required Rocky Linux dependencies.
#
function main() {
    install_dnf_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
