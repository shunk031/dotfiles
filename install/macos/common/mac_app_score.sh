#!/usr/bin/env bash

set -Eeuox pipefail

function install_mas() {
    brew install mas
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

function main() {
    install_mas

    if ! "${CI:-false}"; then
        install_bandwidth_plus
        install_line
    fi
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
