#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/uv.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_04-install-uv.sh.tmpl"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_uv

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] uv" {
    [ -e "${TMPL_SCRIPT_PATH}" ]

    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.cargo/bin"
    [ -x "$(command -v uv)" ]
}
