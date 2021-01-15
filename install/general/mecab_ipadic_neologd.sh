#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "${DOTPATH}"/install/util.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_mecab_ipadic_negolod() {
    declare -r MECAB_IPADIC_NEOLOGD_DIR="$(mktemp -d mecab-ipadic-neologd-XXXXXXXXXX)"
    declare -r MECAB_IPADIC_NEOLOGD_URL="https://github.com/neologd/mecab-ipadic-neologd.git"

    execute \
        "git clone --quiet --depth 1 ${MECAB_IPADIC_NEOLOGD_URL} ${MECAB_IPADIC_NEOLOGD_DIR}" \
        "Clone to ${MECAB_IPADIC_NEOLOGD_DIR}" \
        || return 1

    execute \
        "cd ${MECAB_IPADIC_NEOLOGD_DIR} \
            && ./bin/install-mecab-ipadic-neologd -n -y" \
        "Install" \
        || return 1
}

main() {
    print_in_purple "\n   mecab-ipadic-neologd\n\n"
    install_mecab_ipadic_negolod
}

main
