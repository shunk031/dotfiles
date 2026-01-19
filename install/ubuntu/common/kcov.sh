#!/usr/bin/env bash

# @file install/ubuntu/common/kcov.sh
# @brief Kcov code coverage tool installation script
# @description
#   This script installs kcov, a code coverage testing tool that works
#   with compiled programs. It installs all required dependencies and
#   builds kcov from source.

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

# @description Install kcov build dependencies
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_kcov_dependencies
function install_kcov_dependencies() {
    sudo apt-get install -y "${PACKAGES[@]}"
}

# @description Uninstall kcov build dependencies
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_kcov_dependencies
function uninstall_kcov_dependencies() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

# @description Build and install kcov from source
# @exitcode 0 On successful installation
# @exitcode 1 If build or installation fails
# @example
#   install_kcov
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

# @description Main entry point for the kcov installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./kcov.sh
function main() {
    install_kcov_dependencies
    install_kcov
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
