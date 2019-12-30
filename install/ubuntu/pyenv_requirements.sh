#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_pyenv_requirements() {
    install_package "make" "make"
    install_package "build-essential" "build-essential"
    install_package "libssl-dev" "libssl-dev"
    install_package "zlib1g-dev" "zlib1g-dev"
    install_package "zlib1g-dev" "zlib1g-dev"
    install_package "libbz2-dev" "libbz2-dev"
    install_package "libreadline-dev" "libreadline-dev"
    install_package "libsqlite3-dev" "libsqlite3-dev"
    install_package "wget" "wget"
    install_package "curl" "curl"
    install_package "llvm" "llvm"
    install_package "libncurses5-dev" "libncurses5-dev"
    install_package "xz-utils" "xz-utils"
    # install_package "tk-dev" "tk-dev"
    install_package "libxml2-dev" "libxml2-dev"
    install_package "libxmlsec1-dev" "libxmlsec1-dev"
    install_package "libffi-dev" "libffi-dev"
}

main() {
    print_in_purple "\n   Requirements of building python with pyenv\n\n"
    install_pyenv_requirements
}

main
