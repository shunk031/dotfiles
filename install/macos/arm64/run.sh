#!/usr/bin/env bash

# @file install/macos/arm64/run.sh
# @brief ARM64 macOS installation runner script
# @description
#   This script serves as an entry point for ARM64-specific macOS installation tasks.
#   It outputs the script path for verification purposes.

set -Eeuo pipefail

# @description Main entry point that outputs the script path
# @stdout The relative path to this script
# @exitcode 0 On success
# @example
#   ./run.sh
function main() {
    echo "../install/macos/arm64/run.sh"
}

main
