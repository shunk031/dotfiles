#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n   Emacs\n\n"

install_package "Emacs" "emacs"
