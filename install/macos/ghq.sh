#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_ghq() {
    brew_install "ghq" "ghq"
    execute \
        "mkdir -p ~/ghq" \
        "make directory for ghq to ~/ghq" \
        || return 1
}

main() {
    print_in_purple "\n   Install ghq\n\n"
    install_ghq
}

main
