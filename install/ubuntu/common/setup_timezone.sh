#!/usr/bin/env bash

# @file install/ubuntu/common/setup_timezone.sh
# @brief Configure the Ubuntu timezone non-interactively.
# @description
#   Points the system timezone at `Asia/Tokyo` by default and installs
#   `tzdata` without opening the Debian timezone prompt.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TIMEZONE="${DOTFILES_TIMEZONE:-Asia/Tokyo}"

#
# @description Apply the repository's preferred timezone configuration.
#
function setup_timezone() {
    sudo ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    echo "${TIMEZONE}" | sudo tee /etc/timezone > /dev/null

    sudo --preserve-env=http_proxy,https_proxy,no_proxy \
        DEBIAN_FRONTEND=noninteractive \
        TZ="${TIMEZONE}" \
        apt-get install -y --no-install-recommends tzdata

    sudo \
        DEBIAN_FRONTEND=noninteractive \
        TZ="${TIMEZONE}" \
        dpkg-reconfigure -f noninteractive tzdata
}

#
# @description Configure the Ubuntu timezone.
#
function main() {
    setup_timezone
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
