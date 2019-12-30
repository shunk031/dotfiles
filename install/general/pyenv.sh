#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_pyenv() {
    declare -r PYENV_DIR="${HOME}/.pyenv"
    declare -r PYENV_URL="https://github.com/yyuu/pyenv.git"

    execute \
        "git clone --quiet $PYENV_URL $PYENV_DIR" \
        "Install pyenv" \
        || return 1
}

install_pyenv_virtualenv() {
    declare -r PYENV_VIRTUALENV_DIR="${HOME}/.pyenv/plugins/pyenv-virtualenv"
    declare -r PYENV_VIRTUALENV_URL="https://github.com/yyuu/pyenv-virtualenv.git"

    execute \
        "git clone --quiet $PYENV_VIRTUALENV_URL $PYENV_VIRTUALENV_DIR" \
        "Install pyenv-virtualenv" \
        || return 1
}

main() {
    print_in_purple "\n   pyenv and pyenv-virtualenv\n\n"
    install_pyenv
    install_pyenv_virtualenv
}

main
