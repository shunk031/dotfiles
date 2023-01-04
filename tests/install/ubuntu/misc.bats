#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/misc.sh"
}

@test "install misc" {
    main
    [ "${status}" -eq 0 ]
    [ -x "$(command -v exa)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v opensshclient)" ]
    [ -x "$(command -v zsh)" ]
}
