#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_pyenv_requirements() {
    brew_install "openssl" "openssl"
    brew_install "readline" "readline"
    brew_install "sqlite3" "sqlite3"
    brew_install "xz" "xz"
    brew_install "zlib" "zlib"
}

main() {
    print_in_purple "\n   Requirements of building python with pyenv\n\n"
    install_pyenv_requirements
}

main
