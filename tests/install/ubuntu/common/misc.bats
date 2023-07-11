#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/misc.sh"

function setup() {
    load "./install/common/rust.sh"
    main # install rust

    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_apt_packages

    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-common] PACKAGES for misc" {
    num_packages="${#PACKAGES[@]}"
    [ $num_packages -eq 6 ]

    expected_packages=(
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

@test "[ubuntu-common] misc" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v gpg)" ]
    [ -x "$(command -v jq)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v shellcheck)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v zsh)" ]
}
