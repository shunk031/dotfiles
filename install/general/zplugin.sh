#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_zplugin() {
    declare -r ZPLUGIN_DIR="${HOME}/.zplugin/bin"
    declare -r ZPLUGIN_URL="https://github.com/zdharma/zplugin.git"

    execute \
        "git clone --quiet $ZPLUGIN_URL $ZPLUGIN_DIR" \
        "Install zplugin" \
        || return 1
}

main() {
    print_in_purple "\n   zplugin\n\n"
    install_zplugin
}

main
