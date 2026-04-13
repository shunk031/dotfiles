#!/usr/bin/env bash

# @file install/macos/common/mac_app_store.sh
# @brief Install selected Mac App Store applications.
# @description
#   Ensures the `mas` CLI exists and installs the configured Mac App Store apps
#   when the script is not running in CI.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Check whether the `mas` CLI is available.
#
function is_mas_installed() {
    common -v mas &> /dev/null
}

#
# @description Install the `mas` CLI through Homebrew when needed.
#
function install_mas() {
    if ! is_mas_installed; then
        brew install mas
    fi
}

#
# @description Install a Mac App Store application by its numeric identifier.
# @arg $1 string Mac App Store application identifier.
#
function run_mas_install() {
    local app_id="$1"
    mas install "${app_id}"
}

#
# @description Install Bandwidth+ from the Mac App Store.
#
function install_bandwidth_plus() {
    local app_id="490461369"
    run_mas_install "${app_id}"
}

#
# @description Install LINE from the Mac App Store.
#
function install_line() {
    local app_id="539883307"
    run_mas_install "${app_id}"
}

#
# @description Install 1Password 7 from the Mac App Store.
#
function install_1password7() {
    local app_id="1333542190"
    run_mas_install "${app_id}"
}

#
# @description Install Xcode from the Mac App Store.
#
function install_xcode() {
    local app_id="497799835"
    run_mas_install "${app_id}"
}

#
# @description Install the configured Mac App Store applications.
#
function main() {
    install_mas

    if ! "${CI:-false}"; then
        install_bandwidth_plus
        install_line
        # install_1password7
        # install_xcode
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
