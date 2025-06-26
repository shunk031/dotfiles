#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/nvm.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    uninstall_nvm

    # reset PATH
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] nvm" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export NVM_DIR="/usr/local/nvm"
    source "$NVM_DIR/nvm.sh" # This loads nvm

    [ -x "$(command -v nvm)" ]
}
