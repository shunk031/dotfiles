#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/font.sh"
}

function teardown() {
    run uninstall_nerd_font_roboto_mono
    run uninstall_nerd_font_hack_mono
}

@test "install font" {
    run main

    [ -e "${HOME%/}/Library/Fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/Library/Fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
