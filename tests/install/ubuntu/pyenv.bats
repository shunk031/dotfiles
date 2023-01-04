#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/pyenv.sh"
}

@test "install pyenv requirements" {
    main

    run dpkg -s 'build-essential'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libssl-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'zlib1g-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libbz2-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libreadline-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libsqlite3-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'curl'
    [ "${status}" -eq 0 ]
    run dpkg -s 'llvm'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libncursesw5-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'xz-utils'
    [ "${status}" -eq 0 ]
    run dpkg -s 'tk-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libxml2-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libxmlsec1-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'libffi-dev'
    [ "${status}" -eq 0 ]
    run dpkg -s 'liblzma-dev'
    [ "${status}" -eq 0 ]
}
