#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_rbenv_requirements() {
    brew_install "openssl" "openssl"
    brew_install "libyaml" "libyaml"
    brew_install "libffi" "libffi"
}

main() {
    print_in_purple "\n   Requirements of building ruby with rbenv\n\n"
    install_rbenv_requirements
}

main
