#!/usr/bin/env bash

# Keep this wrapper minimal: CI invokes this script through `bashcov`.
# `-u` is intentionally omitted because strict nounset can propagate through
# bashcov's SHELLOPTS/xtrace path and break third-party scripts under test.
set -Eeo pipefail

function run_common_test() {
    # Common install tests executed on every matrix target.
    bats -r "tests/install/common/"
}

function run_os_specific_test() {
    if [ "${OS}" == "macos-14" ]; then
        # macOS-only install tests.
        bats -r "tests/install/macos/common/"

    elif [ "${OS}" == "ubuntu-latest" ]; then
        # Ubuntu-only install tests.
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
