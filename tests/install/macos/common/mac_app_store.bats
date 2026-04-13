#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/mac_app_store.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] mac app store" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    #
    # On CI, since it does not log into the app store,
    # it simply tests whether `mas` has been successfully installed.
    #
    # run 'mas list | grep LINE'
    # [ "${status}" -eq 0 ]
    # run 'mas list | grep Bandwidth'
    # [ "${status}" -eq 0 ]
}

@test "[macos] mac app store installs configured apps without tailscale" {
    local calls_path="${BATS_TEST_TMPDIR}/mas_calls.txt"
    : > "${calls_path}"

    run env CALLS_PATH="${calls_path}" CI=false bash -c '
        source "'"${SCRIPT_PATH}"'"

        install_mas() {
            :
        }

        mas() {
            echo "$*" >> "${CALLS_PATH}"
        }

        main
    '

    [ "${status}" -eq 0 ]

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"install 490461369"* ]]
    [[ "${output}" == *"install 539883307"* ]]
    [[ "${output}" != *"1475387142"* ]]
}
