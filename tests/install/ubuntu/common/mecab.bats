#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/mecab.sh"
}

@test "install mecab" {
    main

    run dpkg -s 'mecab'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libmecab-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'mecab-ipadic-utf8'
    [ "${status}" -eq 0 ]
}
