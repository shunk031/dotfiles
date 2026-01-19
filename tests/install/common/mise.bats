#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_01-install-mise.sh.tmpl"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_mise

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] mise" {
    [ -e "${TMPL_SCRIPT_PATH}" ]

    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.local/bin"
    [ -x "$(command -v mise)" ]
}
