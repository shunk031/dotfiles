#!/usr/bin/env bash

# @file install/ubuntu/server/misc.sh
# @brief Install optional Ubuntu server packages.
# @description
#   Installs GPU-related utilities when available and always installs
#   OpenCV-related system packages needed by the server environment.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Detect whether an NVIDIA GPU is available on the host.
#
function is_available_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        return 0
    else
        return 1
    fi
}

#
# @description Install GPU monitoring utilities for NVIDIA-equipped hosts.
#
function install_gpu_related_packages() {
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install --no-install-recommends -y \
        nvtop
}

#
# @description Install packages commonly required by OpenCV-based workloads.
#
function install_opencv_related_packages() {
    # To avoid the following error when running OpenCV-based applications:
    # ImportError: libGL.so.1: cannot open shared object file: No such file or directory
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install --no-install-recommends -y \
        libgl1-mesa-dev \
        ncat
}

#
# @description Install optional Ubuntu server packages for the current host.
#
function main() {
    if is_available_gpu; then
        install_gpu_related_packages
    fi

    install_opencv_related_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
