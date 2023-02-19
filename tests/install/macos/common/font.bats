#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/font.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_nerd_font_roboto_mono
    run uninstall_nerd_font_hack_mono
}

@test "[macos] font" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "${HOME%/}/Library/Fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/Library/Fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
