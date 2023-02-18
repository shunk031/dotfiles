#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/misc.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_apt_packages
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 7 ]
}

@test "install_apt_packages" {
    run install_apt_packages

    [ -x "$(command -v exa)" ]
    [ -x "$(command -v gpg)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}

@test "main" {
    run main

    [ -x "$(command -v exa)" ]
    [ -x "$(command -v gpg)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}

@test "run as shellscript" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v exa)" ]
    [ -x "$(command -v gpg)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}
