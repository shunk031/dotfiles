#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerlevel9k_requirements() {

    declare -r FONT_DIR="${HOME}/.local/share/fonts"
    declare -r FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Medium/complete/Roboto%20Mono%20Medium%20Nerd%20Font%20Complete%20Mono.ttf"
    declare -r FONT_NAME="Roboto Mono Nerd Font Complete Mono.ttf"

    install_package "curl" "curl"

    execute \
        "mkdir -p ${FONT_DIR} \
               && cd ${FONT_DIR} \
               && curl -fLo ${FONT_NAME} ${FONT_URL}" \
        "Install Roboto Mono Nerd Font to ${FONT_DIR}" \
        || return 1
}

main() {
    print_in_purple "\n   Install spacemacs requirements\n\n"
    install_powerlevel9k_requirements
}

main
