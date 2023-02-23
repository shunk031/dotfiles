#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_mas_installed() {
    common -v mas &>/dev/null
}

function install_mas() {
    if ! is_mas_installed; then
        brew install mas
    fi
}

function run_mas_install() {
    local app_id="$1"
    mas install "${app_id}"
}

function install_bandwidth_plus() {
    local app_id="490461369"
    run_mas_install "${app_id}"
}

function install_line() {
    local app_id="539883307"
    run_mas_install "${app_id}"
}

function install_1password7() {
    local app_id="1333542190"
    run_mas_install "${app_id}"
}

function install_xcode() {
    local app_id="497799835"
    run_mas_install "${app_id}"
}

function install_tailscale() {
    local app_id="1475387142"
    run_mas_install "${app_id}"
}

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
