#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/container.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_container
}

@test "[macos] container and socktainer" {
    run env DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]

    if ! "${CI:-false}" && is_container_stack_supported_macos; then
        [ -x "$(command -v container)" ]
        [ -x "$(command -v socktainer)" ]
    fi
}
