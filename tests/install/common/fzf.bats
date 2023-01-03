#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "$(chezmoi source-path)/install/common/fzf.sh"
    uninstall_fzf
}

function teardown() {
    uninstall_fzf
}

@test "install fzf (bash)" {
    main
    . "${HOME%/}.bashrc"
    [ -x "$(command -v fzf)" ]
}

@test "install fzf (zsh)" {
    main
    . "${HOME%/}.zshrc"
    [ -x "$(command -v fzf)" ]
}
