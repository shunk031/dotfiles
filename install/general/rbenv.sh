#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_rbenv() {
    declare -r RBENV_DIR="${HOME}/.rbenv"
    declare -r RBENV_URL="https://github.com/rbenv/rbenv.git"

    execute \
        "git clone --quiet $RBENV_URL $RBENV_DIR \
             && cd ${RBENV_DIR} \
             && src/configure \
             && make -C src" \
        "Install rbenv" \
        || return 1
}

install_ruby_build() {
    declare -r RUBY_BUILD_DIR="${HOME}/.rbenv/plugins/ruby-build"
    declare -r RUBY_BUILD_URL="https://github.com/rbenv/ruby-build.git"

    execute \
        "git clone --quiet $RUBY_BUILD_URL $RUBY_BUILD_DIR" \
        "Install ruby-build" \
        || return 1
}

main() {
    print_in_purple "\n   rbenv and ruby-build\n\n"
    install_rbenv
    install_ruby_build
}

main
