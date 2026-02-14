#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_available_gpu() {
    if command -v nvidia-smi &> /dev/null; then
        return 0
    else
        return 1
    fi
}

function install_gpu_related_packages() {
    sudo apt-get update && sudo apt-get install --no-install-recommends -y \
        nvtop
}

function install_opencv_related_packages() {
    # To avoid the following error when running OpenCV-based applications:
    # ImportError: libGL.so.1: cannot open shared object file: No such file or directory
    sudo apt-get update && sudo apt-get install --no-install-recommends -y \
        libgl1-mesa-dev
        
}

function main() {
    if is_available_gpu; then
        install_gpu_related_packages
    fi

    install_opencv_related_packages
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
