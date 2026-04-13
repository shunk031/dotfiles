#!/usr/bin/env bash

# @file install/macos/arm64/run.sh
# @brief Print the arm64 installer entrypoint path.
# @description
#   Emits the relative arm64 installer path consumed by the surrounding setup
#   flow.

set -Eeuo pipefail

#
# @description Print the arm64 installer path.
#
function main() {
    echo "../install/macos/arm64/run.sh"
}

main
