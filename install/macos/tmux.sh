#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh \
    && . "${DOTPATH}"/install/macos/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_tmux_mem_cpu_load() {
    declare -r TMUX_MEM_CPU_LOAD_DIR="/tmp"
    declare -r TMUX_MEM_CPU_LOAD_URL="https://github.com/thewtex/tmux-mem-cpu-load.git"

    brew_install "cmake" "cmake"

    execute \
        "rm -rf ${TMUX_MEM_CPU_LOAD_DIR} \
            && git clone --quiet ${TMUX_MEM_CPU_LOAD_URL} ${TMUX_MEM_CPU_LOAD_DIR} \
            && cd ${TMUX_MEM_CPU_LOAD_DIR} \
            && cmake . \
            && make \
            && sudo make install" \
        "tmux mem cpu load" \
        || return 1
}

main() {
    print_in_purple "\n   tmux\n\n"

    brew_install "tmux" "tmux"
    brew_install "tmux (pasteboard)" "reattach-to-user-namespace"

    install_tmux_mem_cpu_load
    bash "${DOTPATH}"/install/general/tpm.sh
}

main
