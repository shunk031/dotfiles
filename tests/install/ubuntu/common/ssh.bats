#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ssh.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_openssh
}

@test "[ubuntu-common] PACKAGES for ssh" {
    [ ${#PACKAGES[@]} -eq 1 ]
}

@test "[ubuntu-common] ssh" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}
