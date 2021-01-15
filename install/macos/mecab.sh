#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_mecab() {
    brew_install "mecab" "mecab"
    brew_install "mecab-ipadic" "mecab-ipadic"
}

main() {
    print_in_purple "\n   Install mecab\n\n"

    install_mecab
    bash "${DOTPATH}"/install/general/mecab_ipadic_neologd.sh
}

main
