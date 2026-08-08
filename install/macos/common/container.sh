#!/usr/bin/env bash

# @file install/macos/common/container.sh
# @brief Install Apple Container and Socktainer on macOS.
# @description
#   Installs or removes the Apple Container and Socktainer Homebrew formulae
#   and starts their services on supported non-CI macOS hosts.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Return the host macOS major version.
#
function macos_major_version() {
    sw_vers -productVersion | cut -d "." -f 1
}

#
# @description Check whether Apple Container and Socktainer can run on this host.
#
function is_container_stack_supported_macos() {
    local major_version
    major_version="$(macos_major_version)"

    [ "$(uname -m)" = "arm64" ] && [ "${major_version}" -ge 26 ]
}

#
# @description Remove the legacy Apple Container cask when it is installed.
#
function uninstall_legacy_container_cask() {
    if brew list --cask container &> /dev/null; then
        brew uninstall --cask container --force
    fi
}

#
# @description Check whether a Homebrew formula is installed.
# @arg $1 string Homebrew formula token.
#
function is_formula_installed() {
    local formula_token="$1"

    brew list --formula "${formula_token}" &> /dev/null
}

#
# @description Install Apple Container and Socktainer Homebrew formulae.
#
function install_container() {
    if "${CI:-false}"; then
        echo "Skipping Apple Container and Socktainer install in CI."
        return
    fi

    if ! is_container_stack_supported_macos; then
        echo "Skipping Apple Container and Socktainer install because Apple Silicon macOS 26 or newer is required."
        return
    fi

    uninstall_legacy_container_cask
    brew tap socktainer/tap
    brew install container socktainer/tap/socktainer
}

#
# @description Start the Apple Container and Socktainer services on supported non-CI hosts.
#
function start_container_system() {
    if "${CI:-false}" || ! is_container_stack_supported_macos; then
        return
    fi

    brew services start container
    brew services start socktainer
}

#
# @description Remove Apple Container and Socktainer Homebrew packages.
#
function uninstall_container() {
    if "${CI:-false}" || ! is_container_stack_supported_macos; then
        return
    fi

    local formula_token

    brew services stop socktainer || true
    brew services stop container || true

    for formula_token in socktainer container; do
        if is_formula_installed "${formula_token}"; then
            brew uninstall "${formula_token}" --force
        fi
    done

    uninstall_legacy_container_cask
}

#
# @description Run the Apple Container and Socktainer installation flow.
#
function main() {
    install_container
    start_container_system
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
