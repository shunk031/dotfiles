#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/tpm.sh"

function setup() {
    source "./install/ubuntu/common/tmux.sh"
    main # install tmux

    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_tmux
    run uninstall_tpm
    run uninstall_tmux_mem_cpu_load

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-common] tpm" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -e "${HOME%/}/.tmux/plugins/tpm" ]
    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v tmux-mem-cpu-load)" ]
}
