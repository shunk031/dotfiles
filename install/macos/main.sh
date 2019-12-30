#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    declare -r MACOS_DIR="${DOTPATH}/install/macos"

    # General requirements
    bash ${DOTPATH}/install/general/main.sh

    bash ${MACOS_DIR}/xcode.sh
    bash ${MACOS_DIR}/homebrew.sh
    bash ${MACOS_DIR}/misc.sh

    bash ${MACOS_DIR}/zsh.sh
    # bash ${MACOS_DIR}/emacs.sh
    bash ${MACOS_DIR}/tmux.sh
    bash ${MACOS_DIR}/ghq.sh

    # bash ${MACOS_DIR}/pyenv_requirements.sh
    # bash ${MACOS_DIR}/rbenv_requirements.sh

    # bash ${MACOS_DIR}/spacemacs_requirements.sh
}

main
