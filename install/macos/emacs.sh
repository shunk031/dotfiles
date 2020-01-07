#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


install_emacs() {

    declare -r EMACS_DIR="/usr/local/opt/emacs-plus/Emacs.app"
    declare -r APP_DIR="/Applications"

    brew_tap "d12frosted/emacs-plus"
    brew_install "Emacs plus" "emacs-plus"

    execute \
        "ln -sf ${EMACS_DIR} ${APP_DIR}" \
        "Symbolic link ${EMACS_DIR} to ${APP_DIR}" \
        || return 1
}

main() {
    print_in_purple "\n   Emacs\n\n"
    install_emacs
}

main
