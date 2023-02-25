#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/client/misc.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_misc
}

@test "[ubuntu-client] PACKAGES for misc" {
    num_packages="${#PACKAGES[@]}"
    [ $num_packages -eq 2 ]

    expected_packages=(
        guake
        gparted
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
}

@test "[ubuntu-client] misc" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s guake
    [ "${status}" -eq 0 ]
    run dpkg -s gparted
    [ "${status}" -eq 0 ]
}
