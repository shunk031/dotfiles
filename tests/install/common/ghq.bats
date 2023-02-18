#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/ghq.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run remove_ghq_dir
}

@test "make_ghq_dir" {
    run make_ghq_dir
    [ -d "${HOME%/}/ghq" ]
}

@test "main" {
    run main

    [ -d "${HOME%/}/ghq" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -d "${HOME%/}/ghq" ]
}
