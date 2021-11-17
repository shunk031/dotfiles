#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    print_in_purple "\n   tmux\n\n"

    install_package "tmux" "tmux"
    install_package "tmux (pasteboard)" "xsel"
    # install_package "build-essential" "build-essential"
    # install_package "gcc" "gcc"
    install_package "cmake" "cmake"

    install_tmux_mem_cpu_load
    bash "${DOTPATH}"/install/general/tpm.sh
}

main
