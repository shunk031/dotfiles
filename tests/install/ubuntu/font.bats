#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/font.sh"
}

@test "install nerd fonr" {
    main
    [ -e "${HOME%/}/.local/share/fonts/Roboto Mono Nerd Font Complete.ttf" ]
}
