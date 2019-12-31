#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_powerlevel9k_requirements() {
    brew_install "Roboto Mono Nerd Font" "font-robotomono-nerd-font-mono" "homebrew/cask-fonts" "cask"
}

main() {
    print_in_purple "\n   Install spacemacs requirements\n\n"
    install_powerlevel9k_requirements
}

main
