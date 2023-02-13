#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/mac_app_store.sh"
}

@test "install mas" {
    run main
    [ "${status}" -eq 0 ]

    #
    # On CI, since it does not log into the app store,
    # it simply tests whether `mas` has been successfully installed.
    #
    # run 'mas list | grep LINE'
    # [ "${status}" -eq 0 ]
    # run 'mas list | grep Bandwidth'
    # [ "${status}" -eq 0 ]
}
