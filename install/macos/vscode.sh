#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_vscode() {
    declare -r VSCODE_DIR="${DOTPATH}"/.vscode.d
    declare -r APP_DIR="${HOME}/Library/Application\ Support/Code/User"

    declare -r VSCODE_SETTINGS="${VSCODE_DIR}"/settings.json
    declare -r VSCODE_KEYBINDINGS="${VSCODE_DIR}"/keybindings.json

    declare -r CODE_COMMAND="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"

    brew_install "Visual Studio Code" "visual-studio-code" "homebrew/cask" "cask"

    execute \
        "mkdir -p ${APP_DIR}" \
        "Make directory to ${APP_DIR}" \
        || return 1

    execute \
        "ln -sf ${VSCODE_SETTINGS} ${APP_DIR}" \
        "Symbolic link ${VSCODE_SETTINGS} to ${APP_DIR}" \
        || return 1

    execute \
        "ln -sf ${VSCODE_KEYBINDINGS} ${APP_DIR}" \
        "Symbolic link ${VSCODE_SETTINGS} to ${APP_DIR}" \
        || return 1

     grep -v '^#' "${VSCODE_DIR}/extensions" | xargs -L1 "${CODE_COMMAND}" --install-extension

    # execute \
    #     "cat ${VSCODE_DIR}/extensions | grep -v '^#' | xargs -L1 ${CODE_COMMAND} --install-extension" \
    #     "Install extensions from ${VSCODE_DIR}/extensions" \
    #     || return 1
}

main() {
    print_in_purple "\n   Install VSCode\n\n"
    install_vscode
}

main