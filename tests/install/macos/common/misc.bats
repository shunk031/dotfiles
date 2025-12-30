#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/misc.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] misc" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    #
    # brew packages
    #
    run brew info gpg
    [ "${status}" -eq 0 ]
    run brew info imagemagick
    [ "${status}" -eq 0 ]
    run brew info htop
    [ "${status}" -eq 0 ]
    run brew info pinentry-mac
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
