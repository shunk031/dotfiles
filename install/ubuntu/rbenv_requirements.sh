#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_rbenv_requirements() {
    install_package "autoconf" "autoconf"
    install_package "bison" "bison"
    install_package "build-essential" "build-essential"
    install_package "libssl-dev" "libssl-dev"
    install_package "libyaml-dev" "libyaml-dev"
    install_package "libreadline6-dev" "libreadline6-dev"
    install_package "zlib1g-dev" "zlib1g-dev"
    install_package "libncurses5-dev" "libncurses5-dev"
    install_package "libffi-dev" "libffi-dev"
    install_package "libgdbm5" "libgdbm5"
    install_package "libgdbm-dev" "libgdbm-dev"
}

main() {
    print_in_purple "\n   Requirements of building ruby with rbenv\n\n"
    install_rbenv_requirements
}

main
