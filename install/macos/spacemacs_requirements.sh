#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_spacemacs_requirements() {
    brew_install "Source Code Pro" "font-source-code-pro" "homebrew/cask" "cask"
}

main() {
    print_in_purple "\n   Install spacemacs requirements\n\n"
    install_spacemacs_requirements
}
