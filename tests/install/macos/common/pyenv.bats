#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/pyenv.sh"
}

@test "install pyenv requirements (macos)" {
    main

    run brew info openssl
    [ "${status}" -eq 0 ]
    run brew info readline
    [ "${status}" -eq 0 ]
    run brew info sqlite3
    [ "${status}" -eq 0 ]
    run brew info xz
    [ "${status}" -eq 0 ]
    run brew info zlib
    [ "${status}" -eq 0 ]
    run brew info tcl-tk
    [ "${status}" -eq 0 ]
}