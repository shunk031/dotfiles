#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/docker.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] remove docker desktop" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ ! -d "/Applications/Docker.app" ]
}
