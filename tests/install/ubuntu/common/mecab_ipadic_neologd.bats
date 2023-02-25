#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/mecab_ipadic_neologd.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_mecab_ipadic_neologd_requirements
}

@test "[ubuntu-common] PACKAGES for mecab-ipadic-neologd" {
    num_packages="${#PACKAGES[@]}"
    [ ${num_packages} -eq 3 ]

    expected_packages=(
        # git
        make
        # curl
        xz-utils
        file
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
}

@test "[ubuntu-common] mecab-ipadic-neologd" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s make
    [ "${status}" -eq 0 ]
    run dpkg -s curl
    [ "${status}" -eq 0 ]
    run dpkg -s xz-utils
    [ "${status}" -eq 0 ]
    run dpkg -s file
    [ "${status}" -eq 0 ]
}
