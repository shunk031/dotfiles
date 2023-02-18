#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/font.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_nerd_font_roboto_mono
    run uninstall_nerd_font_hack_mono
}

@test "install_nerd_font_roboto_mono" {
    run install_nerd_font_roboto_mono
    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
}

@test "install_nerd_font_hack_mono" {
    run install_nerd_font_hack_mono
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}

@test "main" {
    run main

    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
    [ -e "${HOME%/}/.local/share/fonts/Hack Regular Nerd Font Complete Mono.ttf" ]
}
