#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_mecab_ipadic_neologd_installed() {
    local mecab_ipadic_neologd_path
    mecab_ipadic_neologd_path="$(mecab-config --dicdir)/mecab-ipadic-neologd"

    [ -d "${mecab_ipadic_neologd_path}" ]
}
function clone_mecab_ipadic_neologd() {
    local url="$1"
    local dir="$2"

    git clone --depth 1 "${url}" "${dir}"
}

function install_mecab_ipadic_neologd() {
    local dir="$1"
    local install_cmd_path="${dir%/}/bin/install-mecab-ipadic-neologd"

    exec "${install_cmd_path}" -n -y
}

function main() {

    if [ ! "${DOTFILES_DEBUG:-}" ] && is_mecab_ipadic_neologd_installed; then
        return 0 # early return
    fi

    local mecab_ipadic_neologd_url="https://github.com/neologd/mecab-ipadic-neologd.git"

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/mecab-ipadic-neologd-XXXXXXXXXX)"

    clone_mecab_ipadic_neologd "${mecab_ipadic_neologd_url}" "${tmp_dir}"
    install_mecab_ipadic_neologd "${tmp_dir}"

    # cleanup the temp directory
    rm -rf "${tmp_dir}"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if ! "${CI:-false}"; then
        main
    fi
fi
