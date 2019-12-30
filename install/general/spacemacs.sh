#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_spacemacs() {
    declare -r SPACEMACS_DIR="${HOME}/.emacs.d"
    declare -r SPACEMACS_URL="https://github.com/syl20bnr/spacemacs"

    execute \
        "git clone --quiet $SPACEMACS_URL $SPACEMACS_DIR" \
        "Install Spacemacs" \
        || return 1
}

main() {
    print_in_purple "\n   Spacemacs\n\n"
    install_spacemacs
}

main
