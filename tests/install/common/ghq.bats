#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/ghq.sh"

function setup() {
    load "${SCRIPT_PATH}"
}

function teardown() {
    run remove_ghq_dir
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -d "${HOME%/}/ghq" ]
}
