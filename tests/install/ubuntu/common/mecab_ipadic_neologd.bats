#!/usr/bin/env bats

set -Eeuox pipefail

function setup() {
    . "./install/ubuntu/common/mecab.sh"
    install_mecab
    . "./install/common/mecab_ipadic_neologd.sh"
}

@test "install mecab-ipadic-neologd (ubuntu)" {
    main
}
