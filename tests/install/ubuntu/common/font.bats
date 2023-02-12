#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/font.sh"
}

@test "install nerd font" {
    main

    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
