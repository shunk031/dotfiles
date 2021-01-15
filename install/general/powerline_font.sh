#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerline() {
    declare -r POWERLINE_FONT_DIR="$(mktemp -d /tmp/powerline-XXXXXXXXXX)"
    declare -r POWERLINE_FONT_URL="https://github.com/powerline/fonts.git"

    execute \
        "git clone --quiet  --depth 1 ${POWERLINE_FONT_URL} ${POWERLINE_FONT_DIR}" \
        "Clone to ${POWERLINE_FONT_DIR}"

    execute \
        "${POWERLINE_FONT_DIR}/install.sh" \
        "Install" \
        || return 1
}

install_awesome_powerline() {
    declare -r AWESOME_POWERLINE_FONT_DIR="$(mktemp -d /tmp/awesome-terminal-fonts-XXXXXXXXXX)"
    declare -r AWESOME_POWERLINE_FONT_URL="https://github.com/gabrielelana/awesome-terminal-fonts"

    execute \
        "git clone --quiet ${AWESOME_POWERLINE_FONT_URL} ${AWESOME_POWERLINE_FONT_DIR}" \
        "Clone to ${AWESOME_POWERLINE_FONT_DIR}"

    execute \
        "cd ${AWESOME_POWERLINE_FONT_DIR} && ./build.sh" \
        "Build" \
        || return 1

    execute \
        "cd ${AWESOME_POWERLINE_FONT_DIR} && ./install.sh" \
        "Install" \
        || return 1
}

main() {
    print_in_purple "\n   Powerline font\n\n"

    install_powerline
}

main
