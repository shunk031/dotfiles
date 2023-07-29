#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/pyenv.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_pyenv_requirements
}

@test "[ubuntu-common] PACKAGES for pyenv" {
    num_packages="${#PACKAGES[@]}"
    [ $num_packages -eq 15 ]

    expected_packages=(
        build-essential
        libssl-dev
        zlib1g-dev
        libbz2-dev
        libreadline-dev
        libsqlite3-dev
        curl
        llvm
        libncursesw5-dev
        xz-utils
        tk-dev
        libxml2-dev
        libxmlsec1-dev
        libffi-dev
        liblzma-dev
    )
    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${PACKAGES[$i]}" == "${expected_packages[$i]}" ]
    done
}

@test "[ubuntu-common] pyenv" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s build-essential
    [ "${status}" -eq 0 ]
    run dpkg -s libssl-dev
    [ "${status}" -eq 0 ]
    run dpkg -s zlib1g-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libbz2-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libreadline-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libsqlite3-dev
    [ "${status}" -eq 0 ]
    run dpkg -s curl
    [ "${status}" -eq 0 ]
    run dpkg -s llvm
    [ "${status}" -eq 0 ]
    run dpkg -s libncursesw5-dev
    [ "${status}" -eq 0 ]
    run dpkg -s xz-utils
    [ "${status}" -eq 0 ]
    run dpkg -s tk-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libxml2-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libxmlsec1-dev
    [ "${status}" -eq 0 ]
    run dpkg -s libffi-dev
    [ "${status}" -eq 0 ]
    run dpkg -s liblzma-dev
    [ "${status}" -eq 0 ]
}
