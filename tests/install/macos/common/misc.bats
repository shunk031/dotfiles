#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/misc.sh"
}

@test "install misc (macos)" {
    run main

    #
    # brew packages
    #
    run brew info bats
    [ "${status}" -eq 0 ]
    run brew info exa
    [ "${status}" -eq 0 ]
    run brew info imagemagick
    [ "${status}" -eq 0 ]
    run brew info jq
    [ "${status}" -eq 0 ]
    run brew info hugo
    [ "${status}" -eq 0 ]
    run brew info htop
    [ "${status}" -eq 0 ]
    run brew info shellcheck
    [ "${status}" -eq 0 ]
    run brew info tailscale
    [ "${status}" -eq 0 ]
    run brew info vim
    [ "${status}" -eq 0 ]
    run brew info watchexec
    [ "${status}" -eq 0 ]
    run brew info zsh
    [ "${status}" -eq 0 ]

    #
    # Cask packages
    #

    # Currently, we do not run this test on CI
    # because of the time it takes to install the cask packages.
}
