#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_age_installed() {
    command -v "age" &>/dev/null
}

function get_chezmoi_home_dir() {
    local home_dir
    home_dir=$(chezmoi data | jq -r '.chezmoi.homeDir')
    echo -n "${home_dir}"
}

function get_chezmoi_source_dir() {
    local source_dir
    source_dir=$(chezmoi data | jq -r '.chezmoi.sourceDir')
    echo -n "${source_dir}"
}

function decrypt_age_private_key() {
    local age_dir
    local age_src_key
    local age_dst_key

    if "${CI:-false}"; then
        # age is currently required tty. The CI does not have tty so return early
        return 0 # early return
    fi

    if is_age_installed; then
        age_dir="$(get_chezmoi_home_dir)/.config/age"
        age_src_key="$(get_chezmoi_source_dir)/.key.txt.age"
        age_dst_key="${age_dir}/key.txt"

        if [ ! -f "${age_dst_key}" ]; then
            mkdir -p "${age_dir}"

            echo "Decrypting ${age_src_key} to ${age_dst_key}"
            age --decrypt --output "${age_dst_key}" "${age_src_key}"
            chmod 600 "${age_dst_key}"
        fi
    else
        echo "age (https://github.com/FiloSottile/age) is required to decrypt the files." >&2
        exit 1
    fi
}

function main() {
    decrypt_age_private_key
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
