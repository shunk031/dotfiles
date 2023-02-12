#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/mecab.sh"
}

@test "install mecab (macos)" {
    run main

    [ -x "$(command -v mecab)" ]

    run brew info "mecab-ipadic"
    [ "${status}" -eq 0 ]
}
