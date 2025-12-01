#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/mac_app_store.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] mac app store" {
    if [ "$CI" = "true" ]; then
        skip "Skipping mac app store test on CI environment."
    fi
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run 'mas list | grep LINE'
    [ "${status}" -eq 0 ]
    run 'mas list | grep Bandwidth'
    [ "${status}" -eq 0 ]
}
