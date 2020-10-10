#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerlevel9k_requirements() {
    brew_install "Nerd Fonts" "font-hack-nerd-font" "homebrew/cask" "cask"
}

main() {
    print_in_purple "\n   Install powerlevel9k requirements\n\n"
    install_powerlevel9k_requirements
}

main
