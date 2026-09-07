#!/usr/bin/env bash

# @file install/rocky/server/misc.sh
# @brief Install optional Rocky Linux server packages.
# @description
#   Installs the OpenGL runtime required by OpenCV-based server workloads.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    mesa-libGL
)

#
# @description Install the OpenGL runtime when it is unavailable.
#
function main() {
    if ldconfig -p 2> /dev/null | grep -F 'libGL.so.1' > /dev/null; then
        return 0
    fi

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y "${PACKAGES[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
