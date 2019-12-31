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

main() {
    print_in_purple "\n   tpm\n\n"
    install_tpm
    install_tpm_plugins
}

main
