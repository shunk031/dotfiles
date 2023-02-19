#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mecab_ipadic_neologd.sh"

function setup() {
    source "./install/macos/common/mecab.sh"
    run install_mecab
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_mecab_ipadic_neologd_requirements
}

@test "[macos] mecab-ipadic-neologd" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v curl)" ]
    [ -x "$(command -v xz)" ]
}
