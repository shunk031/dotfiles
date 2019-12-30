#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . ${DOTPATH}/install/util.sh \
    && . ${DOTPATH}/install/ubuntu/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_tmux_mem_cpu_load() {

    declare -r TMUX_MEM_CPU_LOAD_DIR="${DOTPATH}/.github/tmux-mem-cpu-load"
    declare -r TMUX_MEM_CPU_LOAD_URL="https://github.com/thewtex/tmux-mem-cpu-load.git"

    install_package "build-essential" "build-essential"
    install_package "gcc" "gcc"
    install_package "cmake" "cmake"

    execute \
        "git clone --quiet $TMUX_MEM_CPU_LOAD_URL $TMUX_MEM_CPU_LOAD_DIR" \
        "Clone tmux mem cpu load" \

    execute \
        "cd ${TMUX_MEM_CPU_LOAD_DIR} \
            && cmake . \
            && make \
            && sudo make install" \
        "Install tmux mem cpu load" \
        || return 1
}

main() {
    print_in_purple "\n   tmux\n\n"

    install_package "tmux" "tmux"
    install_package "tmux (pasteboard)" "xsel"

    install_tmux_mem_cpu_load
    bash ${DOTPATH}/install/general/tpm.sh
}

main
