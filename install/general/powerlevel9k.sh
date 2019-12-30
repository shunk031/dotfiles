#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerlevel9k() {
    declare -r POWERLEVEL9K_DIR="${HOME}/.zprezto/modules/prompt/external/powerlevel9k"
    # declare -r POWERLEVEL9K_URL="https://github.com/bhilburn/powerlevel9k.git"
    declare -r POWERLEVEL9K_URL="https://github.com/romkatv/powerlevel10k.git"
    declare -r PREZTO_PROMPT_DIR="${HOME}/.zprezto/modules/prompt/functions"

    execute \
        "git clone --quiet $POWERLEVEL9K_URL $POWERLEVEL9K_DIR" \
        "Clone to ${POWERLEVEL9K_DIR}"

    execute \
        "ln -s $POWERLEVEL9K_DIR/powerlevel9k.zsh-theme \
               $PREZTO_PROMPT_DIR/prompt_powerlevel9k_setup" \
        "Install powerlevel9k" \
        || return 1
}

main() {
    print_in_purple "\n   powerlevel9k\n\n"
    install_powerlevel9k
}
