#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/tpm.sh"
}

@test "install tpm" {
    main

    [ -e "${HOME%/}/.tmux/plugins/tpm" ]
    [ -x "$(command -v tmux-mem-cpu-load)" ]
}
