#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mecab_ipadic_neologd.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"
    [ is_mecab_ipadic_neologd_installed ]
}
