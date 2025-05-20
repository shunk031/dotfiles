#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    binutils-dev
    build-essential
    cmake
    git
    libcurl4-openssl-dev
    libdw-dev
    libiberty-dev
    libssl-dev
    ninja-build
    python3
    zlib1g-dev
    libelf-dev
    libstdc++-12-dev
)

function install_kcov_dependencies() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

function uninstall_kcov_dependencies() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function install_kcov() {
    local url="https://github.com/SimonKagstrom/kcov"

    local tmp_dir
    tmp_dir=$(mktemp -d /tmp/kcov-XXXXX)
    
    local kcov_version="v43"
    git clone "${url}" "${tmp_dir}" -b "${kcov_version}" --depth 1 

    cd "${tmp_dir}" || exit 1
    mkdir build && cd build || exit 1
    cmake ..
    make
    sudo make install
}

function main() {
    install_kcov_dependencies
    install_kcov
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
