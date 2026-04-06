#!/usr/bin/env bash

set -Eeo pipefail

function run_common_test() {
    bats -r "tests/install/common/"
}

function run_os_specific_test() {
    if [ "${OS}" == "macos-14" ]; then
        bats -r "tests/install/macos/common/"

    elif [ "${OS}" == "ubuntu-latest" ]; then
        bats -r "tests/install/ubuntu/common/"
    else
        echo "${OS} and ${SYSTEM} are not supported" >&2
        exit 1
    fi
}

function main() {
    run_common_test
    run_os_specific_test
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
