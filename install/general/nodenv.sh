#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_nodenv() {
    declare -r NODENV_DIR="${HOME}/.nodenv"
    declare -r NODENV_URL="https://github.com/nodenv/nodenv.git"

    execute \
        "rm -rf ${NODENV_DIR} \
            && git clone --quiet ${NODENV_URL} ${NODENV_DIR} \
            && cd ${NODENV_DIR} \
            && src/configure \
            && make -C src" \
        "Install to ${NODENV_DIR}" \
        || return 1
}

main() {
    print_in_purple "\n   nodenv\n\n"
    install_nodenv
}
