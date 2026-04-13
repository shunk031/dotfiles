#!/usr/bin/env bash

# @file install/macos/arm64/prepare_arm64_system.sh
# @brief Prepare Apple Silicon hosts for the dotfiles setup.
# @description
#   Installs Rosetta on arm64 macOS machines when it is not already present.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Install Rosetta if the system has not installed it yet.
#
function install_rosetta() {
    local rosetta_path="/Library/Apple/usr/share/rosetta/rosetta"
    if ! [[ -f "${rosetta_path}" ]]; then
        softwareupdate --install-rosetta --agree-to-license
    fi
}

#
# @description Run Apple Silicon system preparation steps.
#
function main() {
    install_rosetta
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
