#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly JAVA_SRC_JDK_PATH="$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk"
readonly JAVA_DST_JDK_PATH="/Library/Java/JavaVirtualMachines/openjdk.jdk"

function install_kotlin() {
    brew install kotlin ktlint
}

function install_gradle() {
    brew install gradle
}

function install_java() {
    brew install java
    sudo ln -sfn "${JAVA_SRC_JDK_PATH}" "${JAVA_DST_JDK_PATH}"
}

function install_android_studio() {
    brew install --cask android-studio
}

function uninstall_kotlin() {
    brew uninstall kotlin ktlint
}

function uninstall_gradle() {
    brew uninstall gradle
}

function uninstall_java() {
    sudo unlink ${JAVA_DST_JDK_PATH}
    brew uninstall java
}

function uninstall_android_studio() {
    brew uninstall android-studio
}

function main() {
    install_java
    install_kotlin
    install_gradle
    install_android_studio
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
