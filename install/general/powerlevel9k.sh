#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerlevel9k() {
    declare -r POWERLEVEL9K_DIR="${HOME}/.zprezto/modules/prompt/external/powerlevel9k"
    declare -r POWERLEVEL9K_URL="https://github.com/romkatv/powerlevel10k.git"
    declare -r PREZTO_PROMPT_DIR="${HOME}/.zprezto/modules/prompt/functions"

    execute \
        "rm -rf ${POWERLEVEL9K_DIR} \
            && git clone --quiet ${POWERLEVEL9K_URL} ${POWERLEVEL9K_DIR}" \
        "Clone to ${POWERLEVEL9K_DIR}" \
        || return 1

    execute \
        "ln -s ${POWERLEVEL9K_DIR}/powerlevel10k.zsh-theme ${PREZTO_PROMPT_DIR}/prompt_powerlevel10k_setup" \
        "Install ${POWERLEVEL9K_DIR}/powerlevel10k.zsh-theme to ${PREZTO_PROMPT_DIR}/prompt_powerlevel10k_setup" \
        || return 1
}

main() {
    print_in_purple "\n   powerlevel9k\n\n"
    install_powerlevel9k
}

main
