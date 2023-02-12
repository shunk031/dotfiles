#!/usr/bin/env bats

@test "install tmux requirements (ubuntu)" {
    . "./install/ubuntu/common/tmux.sh"
    run main

    [ -x "$(command -v tmux)" ]
    [ -x "$(command -v xsel)" ]
    [ -x "$(command -v cmake)" ]
}

@test "install tpm (ubuntu)" {
    . "./install/common/tpm.sh"
    run main

    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -e "${HOME%/}/.tmux/plugins/tpm" ]
    [ -x "$(command -v tmux-mem-cpu-load)" ]
}
