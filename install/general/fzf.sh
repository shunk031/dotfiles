#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_fzf() {
    declare -r FZF_DIR="${HOME}/.fzf"
    declare -r FZF_URL="https://github.com/junegunn/fzf.git"

    execute \
        "rm -rf ${FZF_DIR} \
            && git clone --quiet ${FZF_URL} ${FZF_DIR}" \
        "Clone to ${FZF_DIR}" \
        || return 1

    execute \
        "${FZF_DIR}/install --key-bindings --completion --no-update-rc" \
        "Install" \
        || return 1
}

main() {
    print_in_purple "\n   fzf\n\n"
    install_fzf
}

main
