#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/ghq.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run remove_ghq_dir
}

@test "[common] ghq" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -d "${HOME%/}/ghq" ]
}
