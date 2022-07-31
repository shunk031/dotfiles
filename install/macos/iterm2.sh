#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" &&
    . "${DOTPATH}"/install/util.sh &&
    . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_iterm2() {
    declare -r SRC_JSON="${DOTPATH}"/machines/macos/hotkey_window.json
    declare -r DST_JSON="$HOME"/Library/Application\ Support/iTerm2/DynamicProfiles/hotkey_window.json

    brew_install "iterm2" "iterm2" "homebrew/cask" "cask"
    execute \
        "ln -sfnv $SRC_JSON $DST_JSON" \
        "Create symbolic link from $SRC_JSON to $DST_JSON" || return 1
}

main() {
    print_in_purple "\n   Install iTerm2\n\n"
    install_iterm2
}

main
