#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_prezto() {
    declare -r PREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
    declare -r PREZTO_URL="https://github.com/sorin-ionescu/prezto.git"

    execute \
        "git clone --quiet --recursive $PREZTO_URL $PREZTO_DIR" \
        "Install prezto" \
        || return 1
}

main() {
    print_in_purple "\n   prezto\n\n"
    install_prezto
}

main
