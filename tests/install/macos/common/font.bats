#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/font.sh"
}

@test "install font" {
    main

    [ -e "${HOME%/}/Library/Fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/Library/Fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
