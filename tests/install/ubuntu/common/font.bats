#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/font.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_nerd_font_roboto_mono
    run uninstall_nerd_font_hack_mono
}

@test "[ubuntu-common] font" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
