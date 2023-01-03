#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/gh.sh"
}

@test "install gh" {
    main
    [ -x "$(command -v gh)" ]
}
