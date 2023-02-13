#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/fzf.sh"
}

@test "install fzf" {
    run main

    export PATH="${PATH}:${HOME}/.fzf/bin"
    [ -x "$(command -v fzf)" ]
}
