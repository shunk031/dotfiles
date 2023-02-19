#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/mecab.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] mecab" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v mecab)" ]

    run brew info "mecab-ipadic"
    [ "${status}" -eq 0 ]
}
