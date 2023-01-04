#!/usr/bin/env bash

set -Eeuox pipefail

function clone_mecab_ipadic_neologd() {
    local url="$1"
    local dir="$2"

    git clone --depth 1 "${url}" "${dir}"
}

function install_mecab_ipadic_neologd() {
    local dir="$1"
    local install_cmd_path="${dir%/}/bin/install-mecab-ipadic-neologd"

    "${install_cmd_path}" -n -y
}

function main() {

    local mecab_ipadic_neologd_url="https://github.com/neologd/mecab-ipadic-neologd.git"

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/mecab-ipadic-neologd-XXXXXXXXXX)"

    clone_mecab_ipadic_neologd "${mecab_ipadic_neologd_url}" "${tmp_dir}"
    install_mecab_ipadic_neologd "${tmp_dir}"

    rm -rf "${tmp_dir}"
}

# if [ ${#BASH_SOURCE[@]} = 1 ]; then
#     main
# fi
