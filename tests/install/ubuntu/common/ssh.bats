#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/ssh.sh"
}

function teardown() {
    uninstall_openssh
}

@test "setup ssh" {
    main

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}
