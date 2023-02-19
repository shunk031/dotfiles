#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/docker.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_lima
    run uninstall_colima
    run uninstall_docker_cli
    run uninstall_docker_compose

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "install docker" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v lima)" ]
    [ -x "$(command -v colima)" ]
    [ -x "$(command -v docker)" ]
    [ -x "$(command -v docker-compose)" ]
}
