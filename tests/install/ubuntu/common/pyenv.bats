#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/pyenv.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_pyenv_requirements
}

@test "PACKAGES" {
    [ ${#PACKAGES[@]} -eq 15 ]
}

@test "install_pyenv_requirements" {
    run install_pyenv_requirements

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

@test "main" {
    run main

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

@test "run as shellscript" {
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
