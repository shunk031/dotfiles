#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/mecab_ipadic_neologd.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_mecab_ipadic_neologd_requirements
}

@test "PACKAGES" {
    num_packages="${#PACKAGES[@]}"
    [ ${num_packages} -eq 4 ]

    expected_packages=(
        make
        curl
        xz-utils
        file
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
}

@test "run as shellscript" {
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
