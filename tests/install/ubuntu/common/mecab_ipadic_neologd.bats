#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/mecab_ipadic_neologd.sh"
}

function teardown() {
    uninstall_mecab_ipadic_neologd_requirements
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
