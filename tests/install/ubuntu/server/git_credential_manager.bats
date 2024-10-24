#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/server/git_credential_manager.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_git_credential_manager
}

@test "[ubuntu-server] starship" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v git-credential-manager)" ]
}
