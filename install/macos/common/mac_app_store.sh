#!/usr/bin/env bash

# @file install/macos/common/mac_app_store.sh
# @brief Mac App Store applications installation script
# @description
#   This script installs mas (Mac App Store CLI) and uses it to install
#   various applications from the Mac App Store.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Check if mas CLI tool is installed
# @exitcode 0 If mas is installed
# @exitcode 1 If mas is not installed
function is_mas_installed() {
    common -v mas &>/dev/null
}

# @description Install mas (Mac App Store CLI) via Homebrew
# @exitcode 0 On success or if already installed
# @exitcode 1 If installation fails
# @example
#   install_mas
function install_mas() {
    if ! is_mas_installed; then
        brew install mas
    fi
}

# @description Install an application from Mac App Store using mas
# @arg $1 string The App Store application ID
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   run_mas_install "497799835"
function run_mas_install() {
    local app_id="$1"
    mas install "${app_id}"
}

# @description Install Bandwidth+ app from Mac App Store
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_bandwidth_plus
function install_bandwidth_plus() {
    local app_id="490461369"
    run_mas_install "${app_id}"
}

# @description Install LINE app from Mac App Store
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_line
function install_line() {
    local app_id="539883307"
    run_mas_install "${app_id}"
}

# @description Install 1Password 7 app from Mac App Store
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_1password7
function install_1password7() {
    local app_id="1333542190"
    run_mas_install "${app_id}"
}

# @description Install Xcode from Mac App Store
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_xcode
function install_xcode() {
    local app_id="497799835"
    run_mas_install "${app_id}"
}

# @description Install Tailscale app from Mac App Store
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_tailscale
function install_tailscale() {
    local app_id="1475387142"
    run_mas_install "${app_id}"
}

# @description Main entry point for Mac App Store applications installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./mac_app_store.sh
function main() {
    install_mas

    if ! "${CI:-false}"; then
        install_bandwidth_plus
        install_line
        install_tailscale
        # install_1password7
        # install_xcode
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
