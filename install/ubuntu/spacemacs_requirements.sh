#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_spacemacs_requirements() {
    declare -r FONT_DIR="${HOME}/.fonts/adobe-fonts/source-code-pro"
    declare -r FONT_URL="https://github.com/adobe-fonts/source-code-pro.git"

    execute \
        "rm -rf ${FONT_DIR} \
            && git clone --quiet --depth 1 --branch release $FONT_URL $FONT_DIR \
            && fc-cache -f $FONT_DIR" \
        "Install font: Source Code Pro" \
        || return 1
}

main() {
    print_in_purple "\n   Install spacemacs requirements\n\n"
    install_spacemacs_requirements
}

main
