#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_ghq() {

    if ! package_is_installed "golang"; then
        install_package "software-properties-common" "software-properties-common"

        add_ppa "longsleep/golang-backports" \
            || print_error "golang 1.13"

        update &> /dev/null \
            || print_error "golang 1.13 (resync package index files)"
    fi

    install_package "golang 1.13" "golang"

    execute \
        "go get github.com/motemen/ghq && mkdir -p ${HOME}/ghq" \
        "ghq" \
        || return 1
}

main() {
    print_in_purple "\n   Install ghq\n\n"
    install_ghq
}

main
