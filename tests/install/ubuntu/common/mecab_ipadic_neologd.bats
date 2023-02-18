#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/mecab_ipadic_neologd.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_mecab_ipadic_neologd_requirements
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 4 ]
}

@test "install_mecab_ipadic_neologd_requirements" {
    run install_mecab_ipadic_neologd_requirements

    run dpkg -s make
    [ "${status}" -eq 0 ]
    run dpkg -s curl
    [ "${status}" -eq 0 ]
    run dpkg -s xz-utils
    [ "${status}" -eq 0 ]
    run dpkg -s file
    [ "${status}" -eq 0 ]
}

@test "main" {
    run main

    run dpkg -s make
    [ "${status}" -eq 0 ]
    run dpkg -s curl
    [ "${status}" -eq 0 ]
    run dpkg -s xz-utils
    [ "${status}" -eq 0 ]
    run dpkg -s file
    [ "${status}" -eq 0 ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s make
    [ "${status}" -eq 0 ]
    run dpkg -s curl
    [ "${status}" -eq 0 ]
    run dpkg -s xz-utils
    [ "${status}" -eq 0 ]
    run dpkg -s file
    [ "${status}" -eq 0 ]
}
