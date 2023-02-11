#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/ssh.sh"
}

@test "setup ssh" {
    main

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}
