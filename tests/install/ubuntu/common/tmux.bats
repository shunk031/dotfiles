#!/usr/bin/env bats

set -Eeuo pipefail

@test "install tmux requirements (ubuntu)" {
    . "./install/ubuntu/common/tmux.sh"
    run main

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]

    . "./install/common/tpm.sh"
    run main

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -e "${HOME%/}/.tmux/plugins/tpm" ]
    [ -x "$(command -v tmux-mem-cpu-load)" ]
}
