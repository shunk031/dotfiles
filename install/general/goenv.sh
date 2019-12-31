#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_goenv() {
    declare -r GOENV_DIR="${HOME}/.goenv"
    declare -r GOENV_URL="https://github.com/syndbg/goenv.git"

    execute \
        "rm -rf ${GOENV_DIR} \
            && git clone --quiet ${GOENV_URL} ${GOENV_DIR}" \
        "Install to ${GOENV_DIR}" \
        || return 1
}

main() {
    print_in_purple "\n   goenv\n\n"
    install_goenv
}

main
