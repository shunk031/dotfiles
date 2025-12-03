#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/dotenvx.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_dotenvx

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] dotenvx" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.local/bin"
    [ -x "$(command -v dotenvx)" ]
}
