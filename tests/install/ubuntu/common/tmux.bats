#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/ubuntu/common/tmux.sh"
}

@test "install tmux requirements (ubuntu)" {
    main
    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}
