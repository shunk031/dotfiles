#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/client/misc.sh"
}

function teardown() {
    run uninstall_misc
}

@test "install misc (ubuntu client)" {
    run main

    run dpkg -s guake
    [ "${status}" -eq 0 ]
    run dpkg -s gparted
    [ "${status}" -eq 0 ]
}
