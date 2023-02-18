#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ssh.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_openssh
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 1 ]
}

@test "install_openssh" {
    run install_openssh

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}

@test "main" {
    run main

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}

@test "main with set -x" {
    set -x
    run main

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}
