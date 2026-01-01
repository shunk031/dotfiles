#!/usr/bin/env bash

# @file install/ubuntu/server/setup_timezone.sh
# @brief System timezone configuration script for Ubuntu
# @description
#   This script sets the system timezone to Asia/Tokyo and installs
#   the tzdata package to ensure timezone data is available.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Configure system timezone to Asia/Tokyo
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./setup_timezone.sh
function main() {
    export TZ="Asia/Tokyo"
    sudo ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone

    DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y tzdata
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
