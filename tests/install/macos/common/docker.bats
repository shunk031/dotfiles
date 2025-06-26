#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/docker.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_docker
}

@test "[macos] docker" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v docker)" ]
    # [ -x "$(command -v docker-compose)" ]
}
