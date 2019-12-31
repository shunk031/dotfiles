#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    declare -r UBUNTU_DIR="${DOTPATH}/install/ubuntu"

    # General requirements
    bash ${DOTPATH}/install/general/main.sh

    bash ${UBUNTU_DIR}/zsh.sh
    # bash ${UBUNTU_DIR}/emacs.sh
    bash ${UBUNTU_DIR}/tmux.sh
    # bash ${UBUNTU_DIR}/ghq.sh

    # bash ${UBUNTU_DIR}/pyenv_requirements.sh
    # bash ${UBUNTU_DIR}/rbenv_requirements.sh

    # bash ${UBUNTU_DIR}/spacemacs_requirements.sh
    bash ${UBUNTU_DIR}/powerlevel9k_requirements.sh
}

main
