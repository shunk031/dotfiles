#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


install_emacs() {

    declare -r APP_DIR="~/Applications"

    declare -r EMACS_PLUS_VERSION="28"
    declare -r EMACS_VERSION="${EMACS_PLUS_VERSION}.0.50"
    declare -r EMACS_DIR="$(brew --prefix)/Cellar/emacs-plus@${EMACS_PLUS_VERSION}/${EMACS_VERSION}/Emacs.app"

    brew_tap "d12frosted/emacs-plus"
    brew_install "Emacs plus" "emacs-plus@${EMACS_PLUS_VERSION}"

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
