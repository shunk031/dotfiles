#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_tpm() {
    declare -r TPM_DIR="${HOME}/.tmux/plugins/tpm"
    declare -r TPM_URL="https://github.com/tmux-plugins/tpm"

    execute \
        "rm -rf ${TPM_DIR} \
            && git clone --quiet ${TPM_URL} ${TPM_DIR}" \
        "Install tpm (tmux plugin manager)" \
        || return 1
}

install_tpm_plugins() {
    declare -r TPM_DIR="${HOME}/.tmux/plugins/tpm"

    execute \
        "bash ${TPM_DIR}/scripts/install_plugins.sh" \
        "Install tpm plugins" \
        || return 1
}

install_tmux_mem_cpu_load() {
    declare -r TMUX_MEM_CPU_LOAD_DIR="$(mktemp -d /tmp/tmux-mem-cpu-load-XXXXXXXXXX)"
    declare -r TMUX_MEM_CPU_LOAD_URL="https://github.com/thewtex/tmux-mem-cpu-load.git"

    execute \
        "git clone --quiet ${TMUX_MEM_CPU_LOAD_URL} ${TMUX_MEM_CPU_LOAD_DIR} \
            && cd ${TMUX_MEM_CPU_LOAD_DIR} \
            && cmake . -DCMAKE_INSTALL_PREFIX=$HOME \
            && make \
            && make install" \
        "tmux mem cpu load" \
        || return 1
}

main() {
    print_in_purple "\n   tpm\n\n"
    install_tpm
    install_tpm_plugins
    install_tmux_mem_cpu_load
}

main
