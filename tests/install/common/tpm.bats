#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/tpm.sh"

@test "[common] uninstall_tpm calls rm for TPM_DIR" {
    local args_path="${BATS_TEST_TMPDIR}/uninstall_tpm_args.txt"

    run env ARGS_PATH="${args_path}" DOTFILES_DEBUG= bash -c '
        source "'"${SCRIPT_PATH}"'"

        rm() {
            echo "$*" > "${ARGS_PATH}"
        }

        uninstall_tpm
    '
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "-rfv ${HOME%/}/.tmux/plugins/tpm" ]
}

@test "[common] is_tmux_mem_cpu_load_installed checks command -v" {
    run env DOTFILES_DEBUG= bash -c '
        source "'"${SCRIPT_PATH}"'"

        command() {
            if [ "$1" = "-v" ] && [ "$2" = "tmux-mem-cpu-load" ]; then
                return 0
            fi
            builtin command "$@"
        }

        is_tmux_mem_cpu_load_installed
    '

    [ "${status}" -eq 0 ]
}

@test "[common] uninstall_tmux_mem_cpu_load calls rm for binary path" {
    local args_path="${BATS_TEST_TMPDIR}/uninstall_tmux_mem_cpu_load_args.txt"

    run env ARGS_PATH="${args_path}" DOTFILES_DEBUG= bash -c '
        source "'"${SCRIPT_PATH}"'"

        rm() {
            echo "$*" > "${ARGS_PATH}"
        }

        uninstall_tmux_mem_cpu_load
    '
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "-fv ${HOME%/}/.local/bin/tmux-mem-cpu-load" ]
}
