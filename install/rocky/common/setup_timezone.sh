#!/usr/bin/env bash

# @file install/rocky/common/setup_timezone.sh
# @brief Configure the Rocky Linux timezone.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TIMEZONE="${DOTFILES_TIMEZONE:-Asia/Tokyo}"

#
# @description Apply the repository's preferred timezone with systemd.
#
function setup_timezone() {
    if cmp -s /etc/localtime "/usr/share/zoneinfo/${TIMEZONE}"; then
        return 0
    fi

    sudo timedatectl set-timezone "${TIMEZONE}"
}

#
# @description Configure the Rocky Linux timezone.
#
function main() {
    setup_timezone
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
