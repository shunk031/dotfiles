#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/mecab.sh"
    install_mecab
    . "./install/common/mecab_ipadic_neologd.sh"
}

@test "install mecab-ipadic-neologd (macos)" {
    main

    [ -x "$(command -v git)" ]
    [ -x "$(command -v curl)" ]
    [ -x "$(command -v xz)" ]
}
