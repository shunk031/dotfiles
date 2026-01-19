#!/usr/bin/env bash

# @file install/macos/arm64/prepare_arm64_system.sh
# @brief ARM64 macOS system preparation script
# @description
#   This script prepares an ARM64 (Apple Silicon) macOS system by installing
#   Rosetta 2, which enables running x86_64 applications on ARM architecture.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Install Rosetta 2 translation layer for x86_64 compatibility
# @exitcode 0 On success or if Rosetta is already installed
# @exitcode 1 If installation fails
# @example
#   install_rosetta
function install_rosetta() {
    local rosetta_path="/Library/Apple/usr/share/rosetta/rosetta"
    if ! [[ -f "${rosetta_path}" ]]; then
        softwareupdate --install-rosetta --agree-to-license
    fi
}

# @description Main entry point for ARM64 system preparation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./prepare_arm64_system.sh
function main() {
    install_rosetta
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
