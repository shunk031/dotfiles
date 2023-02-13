#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/font.sh"
}

function teardown() {
    uninstall_nerd_font_roboto_mono
    uninstall_nerd_font_hack_mono
}

@test "install nerd font" {
    run main

    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
