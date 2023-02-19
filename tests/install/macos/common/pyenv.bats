#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/pyenv.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] pyenv" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

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
