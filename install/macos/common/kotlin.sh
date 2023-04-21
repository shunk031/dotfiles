#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_kotlin() {
    brew install kotlin
}

function install_gradle() {
    brew install gradle
}

function install_java() {
    local src_file
    src_file="$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk"
    local dst_file="/Library/Java/JavaVirtualMachines/openjdk.jdk"

    sudo ln -sfn "${src_file}" "${dst_file}"
}

function install_android_studio() {
    brew install --cask android-studio
}

function main() {
    install_kotlin
    install_gradle
    install_android_studio
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
