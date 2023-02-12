#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/mecab.sh"
    install_mecab
    . "./install/common/mecab_ipadic_neologd.sh"
}

@test "install mecab-ipadic-neologd (ubuntu)" {
    main

    run dpkg -s 'git'
    [ "${status}" -eq 0 ]
    run dpkg -s 'make'
    [ "${status}" -eq 0 ]
    run dpkg -s 'curl'
    [ "${status}" -eq 0 ]
    run dpkg -s 'xz-utils'
    [ "${status}" -eq 0 ]
    run dpkg -s 'file'
    [ "${status}" -eq 0 ]
}
