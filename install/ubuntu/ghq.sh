#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_ghq() {

    declare -r GOLANG_VERSION="1.15"

    if ! package_is_installed "golang"; then
        install_package "software-properties-common" "software-properties-common"

        add_ppa "longsleep/golang-backports" \
            || print_error "golang ${GOLANG_VERSION}"

        update &> /dev/null \
            || print_error "golang ${GOLANG_VERSION} (resync package index files)"
    fi

    install_package "golang ${GOLANG_VERSION}" "golang-go"

    go version

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
