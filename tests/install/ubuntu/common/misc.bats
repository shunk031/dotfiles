#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/dependencies.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_apt_packages

    PATH=$(getconf PATH)
    export PATH
}

@test "[ubuntu-common] PACKAGES for dependencies" {
    num_packages="${#PACKAGES[@]}"
    [ $num_packages -eq 10 ]

    expected_packages=(
        busybox
        curl
        git
        gpg
        htop
        sudo
        unzip
        vim
        wget
        zsh
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
}

@test "[ubuntu-common] dependencies" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v busybox)" ]
    [ -x "$(command -v curl)" ]
    [ -x "$(command -v git)" ]
    [ -x "$(command -v gpg)" ]
    [ -x "$(command -v htop)" ]
    [ -x "$(command -v sudo)" ]
    [ -x "$(command -v vim)" ]
    [ -x "$(command -v wget)" ]
    [ -x "$(command -v zsh)" ]
}
