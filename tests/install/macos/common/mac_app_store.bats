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
