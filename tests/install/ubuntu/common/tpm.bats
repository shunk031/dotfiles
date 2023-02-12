#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/tmux.sh"
    main # install tmux
    . "./install/common/tpm.sh"
}

function teardown() {
    uninstall_tmux
    uninstall_tpm
    uninstall_tmux_mem_cpu_load
}

@test "install tpm (ubuntu)" {
    run main

    [ -e "${HOME%/}/.tmux/plugins/tpm" ]
    export PATH="${PATH}:${HOME%/}/.local/bin"
    [ -x "$(command -v tmux-mem-cpu-load)" ]
}
