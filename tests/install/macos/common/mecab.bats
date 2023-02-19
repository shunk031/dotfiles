#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/mecab.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

@test "install mecab (macos)" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v mecab)" ]

    run brew info "mecab-ipadic"
    [ "${status}" -eq 0 ]
}
