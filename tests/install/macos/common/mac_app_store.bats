#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/mac_app_store.sh"
}

@test "install mas" {
    main

    run 'mas list | grep LINE'
    [ "${status}" -eq 0 ]
    run 'mas list | grep Bandwidth'
    [ "${status}" -eq 0 ]
}
