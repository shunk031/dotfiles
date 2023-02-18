#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/mecab.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_mecab
}

@test "install_mecab" {
    run install_mecab

    run dpkg -s mecab
    [ "${status}" -eq 0 ]
    run dpkg -s libmecab-dev
    [ "${status}" -eq 0 ]
    run dpkg -s mecab-ipadic-utf8
    [ "${status}" -eq 0 ]
}

@test "main" {
    run main

    run dpkg -s mecab
    [ "${status}" -eq 0 ]
    run dpkg -s libmecab-dev
    [ "${status}" -eq 0 ]
    run dpkg -s mecab-ipadic-utf8
    [ "${status}" -eq 0 ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s mecab
    [ "${status}" -eq 0 ]
    run dpkg -s libmecab-dev
    [ "${status}" -eq 0 ]
    run dpkg -s mecab-ipadic-utf8
    [ "${status}" -eq 0 ]
}
