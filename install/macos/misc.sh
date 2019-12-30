#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Miscellaneous\n\n"

brew_install "gcc" "gcc"
brew_install "fontforge" "fontforge"
brew_install "aspell" "aspell"
brew_install "autossh" "autossh"
brew_install "ag" "ag"
