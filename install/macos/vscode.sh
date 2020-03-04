#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_vscode() {
    declare -r VSCODE_DIR="${DOTPATH}"/.vscode.d
    declare -r APP_DIR="${HOME}/Library/Application\ Support/Code/User"

    brew_install "Visual Studio Code" "visual-studio-code" "homebrew/cask" "cask"

    execute \
        "ln -fnsv ${VSCODE_DIR} ${APP_DIR}" \
        "Symbolic link ${VSCODE_DIR} to ${APP_DIR}" \
        || return 1

    execute \
        "cat ${VSCODE_DIR}/extensions | grep -v '^#' | xargs -L1 code --install-extension" \
        "Install extensions from ${VSCODE_DIR}/extensions" \
        || return 1
}

main() {
    print_in_purple "\n   Install VSCode\n\n"
    install_vscode
}

main