#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/common/mecab_ipadic_neologd.sh"
}

@test "install mecab-ipadic-neologd (common)" {
    run main
    [ is_mecab_ipadic_neologd_installed ]
}
