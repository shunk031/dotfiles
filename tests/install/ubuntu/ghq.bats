#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/golang.sh"
    main

    . "$(chezmoi source-path)/install/ubuntu/common/ghq.sh"
}

@test "install ghq" {
    main
    [ -x "$(command -v ghq)" ]
}
