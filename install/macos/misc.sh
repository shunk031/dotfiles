#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "${DOTPATH}"/install/util.sh &&
    . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Miscellaneous\n\n"

brew_install "gcc" "gcc"
brew_install "fontforge" "fontforge"
brew_install "aspell" "aspell"
brew_install "autossh" "autossh"
brew_install "ag" "ag"
brew_install "shellcheck" "shellcheck"
brew_install "hadolint" "hadolint"
brew_install "htop" "htop"
brew_install "exa" "exa"
brew_install "cmigemo" "cmigemo"
brew_install "hugo" "hugo"
brew_install "1password" "1password" "homebrew/cask" "cask"
