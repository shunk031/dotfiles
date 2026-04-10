#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/chezmoi_private.sh"

@test "[common] install_chezmoi_private returns success when chezmoi init succeeds" {
    run bash -lc "
        source '${SCRIPT_PATH}'
        function chezmoi() { return 0; }
        install_chezmoi_private
    "
    [ "${status}" -eq 0 ]
}

@test "[common] install_chezmoi_private continues when chezmoi init fails" {
    run bash -lc "
        source '${SCRIPT_PATH}'
        function chezmoi() { return 1; }
        install_chezmoi_private
    "
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Warning: Failed to initialize dotfiles-private. Skipping private dotfiles setup."* ]]
}

@test "[common] script enables xtrace when DOTFILES_DEBUG is set" {
    run env DOTFILES_DEBUG=1 bash -c '
        source "'"${SCRIPT_PATH}"'"

        case "$-" in
            *x*)
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
    '

    [ "${status}" -eq 0 ]
}
