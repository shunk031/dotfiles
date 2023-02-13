#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/client/misc.sh"
}

@test "install misc (ubuntu client)" {
    main

    run dpkg -s 'guake'
    [ "${status}" -eq 0 ]
    run dpkg -s 'gparted'
    [ "${status}" -eq 0 ]
}
