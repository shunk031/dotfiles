#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_fzf() {
    declare -r FZF_DIR="${HOME}/.fzf"
    declare -r FZF_URL="https://github.com/junegunn/fzf.git"

    execute \
        "git clone --quiet $FZF_URL $FZF_DIR" \
        "Clone fzf" \

    execute \
        "${FZF_DIR}/install --key-bindings --completion --no-update-rc" \
        "Install fzf" \
        || return 1
}

main() {
    print_in_purple "\n   fzf\n\n"
    install_fzf
}

main
