#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerline() {
    declare -r POWERLINE_FONT_DIR="${DOTPATH}/.github/powerline_fonts"
    declare -r POWERLINE_FONT_URL="https://github.com/powerline/fonts.git"

    execute \
        "rm -rf ${POWERLINE_FONT_DIR} \
            && git clone --quiet ${POWERLINE_FONT_URL} ${POWERLINE_FONT_DIR} --depth=1" \
        "Clone to ${POWERLINE_FONT_DIR}"

    execute \
        "${POWERLINE_FONT_DIR}/install.sh" \
        "Install" \
        || return 1
}

install_awesome_powerline() {
    declare -r AWESOME_POWERLINE_FONT_DIR="${DOTPATH}/.github/awesome_powerline_fonts"
    declare -r AWESOME_POWERLINE_FONT_URL="https://github.com/gabrielelana/awesome-terminal-fonts"

    execute \
        "rm -rf ${AWESOME_POWERLINE_FONT_DIR} \
            && git clone --quiet ${AWESOME_POWERLINE_FONT_URL} ${AWESOME_POWERLINE_FONT_DIR}" \
        "Clone to ${AWESOME_POWERLINE_FONT_DIR}"

    execute \
        "cd $AWESOME_POWERLINE_FONT_DIR && ./build.sh" \
        "Build" \
        || return 1

    execute \
        "cd $AWESOME_POWERLINE_FONT_DIR && ./install.sh" \
        "Install" \
        || return 1
}

install_nerd_font() {
    declare -r NERD_FONT_DIR="${DOTPATH}.github/nerd_font"
    declare -r NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts"

    execute \
        "rm -rf ${NERD_FONT_DIR} \
            && git clone --quiet --branch=master --depth 1 ${NERD_FONT_URL} ${NERD_FONT_DIR}" \
        "Clone to ${NERD_FONT_DIR}"

    execute \
        "cd ${NERD_FONT_DIR} && ./install.sh" \
        "Install" \
        || return 1
}

main() {
    print_in_purple "\n   Powerline font\n\n"

    install_powerline
    # install_nerd_font
}

main
