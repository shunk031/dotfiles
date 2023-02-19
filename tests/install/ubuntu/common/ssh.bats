#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ssh.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_openssh
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 1 ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}
