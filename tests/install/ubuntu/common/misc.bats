#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/misc.sh"
}

@test "install misc" {
    main
    [ -x "$(command -v exa)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}
