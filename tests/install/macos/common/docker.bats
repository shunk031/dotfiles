#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/docker.sh"
}

function teardown() {
    uninstall_lima
    uninstall_colima
    uninstall_docker_cli
    uninstall_docker_compose
}

@test "install docker" {
    run main

    export "${HOME%/}/.local/bin"
    [ -x "$(command -v lima)" ]
    [ -x "$(command -v colima)" ]
    [ -x "$(command -v docker)" ]
    [ -x "$(command -v docker-compose)" ]
}
