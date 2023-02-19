#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/misc.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_apt_packages
}

@test "PACKAGES" {
    num_packages="${#PACKAGES[@]}"
    [ $num_packages -eq 7 ]

    expected_packages=(
        exa
        gpg
        jq
        htop
        shellcheck
        vim
        zsh
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
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
