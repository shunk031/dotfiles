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

    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh" # This loads nvm
    
    # Check if nvm is installed
    # Similar to other tests, nvm runs in a subshell, so even if it is installed correctly, 
    # we cannot verify it as expected. Therefore, we check whether nvm exists 
    # to confirm that the installation was successful.
    # ref. which nvm returns nothing · Issue #540 · nvm-sh/nvm https://github.com/nvm-sh/nvm/issues/540 
    [ "$(command -v nvm 2>/dev/null)" != "" ]
}
