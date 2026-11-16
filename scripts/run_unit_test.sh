#!/usr/bin/env bash

# @file scripts/run_unit_test.sh
# @brief Run the repository's shell unit tests.
# @description
#   Runs the offline inbox fan-out smoke check, then dispatches the common Bats
#   suite and the OS-specific suite selected by `TARGET_OS`.

# Keep this wrapper minimal: CI invokes this script through `bashcov`.
# `-u` is intentionally omitted because strict nounset can propagate through
# bashcov's SHELLOPTS/xtrace path and break third-party scripts under test.
set -Eeo pipefail

#
# @description Run the install tests shared across all CI targets.
#
function run_common_test() {
    # Common install tests executed on every matrix target.
    bash "tests/install/common/claude_inbox_pull_fanout.sh"
    bats -r "tests/install/common/"
}

#
# @description Run the OS-specific Bats suite for the active CI target.
#
function run_os_specific_test() {
    case "${TARGET_OS:-}" in
    macos-14)
        # macOS-only install tests.
        bats -r "tests/install/macos/common/"
        ;;
    ubuntu | ubuntu-latest)
        # Ubuntu-only install tests.
        bats -r "tests/install/ubuntu/common/"
        ;;
    rockylinux)
        # Rocky Linux-only install tests.
        bats -r "tests/install/rockylinux/"
        ;;
    *)
        echo "${TARGET_OS:-<unset>} are not supported" >&2
        exit 1
        ;;
    esac
}

#
# @description Validate the target and run the full unit test flow used by CI.
#
function main() {
    case "${TARGET_OS:-}" in
    macos-14 | ubuntu | ubuntu-latest | rockylinux)
        ;;
    *)
        echo "${TARGET_OS:-<unset>} are not supported" >&2
        exit 1
        ;;
    esac

    run_common_test
    run_os_specific_test
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
