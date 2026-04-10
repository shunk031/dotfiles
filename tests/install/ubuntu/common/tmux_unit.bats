#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/tmux.sh"

@test "[ubuntu-common] uninstall_tmux issues apt remove for package list" {
    local args_path="${BATS_TEST_TMPDIR}/uninstall_tmux_args.txt"

    run env ARGS_PATH="${args_path}" DOTFILES_DEBUG= bash -c '
        source "'"${SCRIPT_PATH}"'"

        sudo() {
            echo "$*" > "${ARGS_PATH}"
        }

        uninstall_tmux
    '
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "apt-get remove -y tmux" ]
}
