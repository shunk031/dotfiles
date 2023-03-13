#!/usr/bin/env bats

readonly SCRIPT_PATH_MACOS="./install/macos/common/mecab_ipadic_neologd.sh"
readonly SCRIPT_PATH_COMMON="./install/common/mecab_ipadic_neologd.sh"

function setup() {
    source "${SCRIPT_PATH_MACOS}"
    source "${SCRIPT_PATH_COMMON}"
}

function teardown() {
    run uninstall_mecab_ipadic_neologd_requirements
}

@test "[macos] mecab-ipadic-neologd" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH_MACOS}"
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH_COMMON}"

    [ -x "$(command -v git)" ]
    [ -x "$(command -v curl)" ]
    [ -x "$(command -v xz)" ]
}
