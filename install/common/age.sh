#!/usr/bin/env bash

# @file install/common/age.sh
# @brief Age encryption tool private key decryption script
# @description
#   This script handles the decryption of age private keys for chezmoi.
#   It checks for age installation and decrypts the encrypted private key
#   file to the appropriate configuration directory.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Check if age command is available in PATH
# @exitcode 0 If age is installed
# @exitcode 1 If age is not installed
function is_age_installed() {
    command -v "age" &>/dev/null
}

# @description Get the chezmoi home directory path
# @stdout The home directory path from chezmoi data
# @exitcode 0 On success
# @example
#   home_dir=$(get_chezmoi_home_dir)
function get_chezmoi_home_dir() {
    local home_dir
    home_dir=$(chezmoi data | jq -r '.chezmoi.homeDir')
    echo -n "${home_dir}"
}

# @description Get the chezmoi source directory path
# @stdout The source directory path from chezmoi data
# @exitcode 0 On success
# @example
#   source_dir=$(get_chezmoi_source_dir)
function get_chezmoi_source_dir() {
    local source_dir
    source_dir=$(chezmoi data | jq -r '.chezmoi.sourceDir')
    echo -n "${source_dir}"
}

# @description Decrypt the age private key from chezmoi source to config directory
# @exitcode 0 On success or if running in CI environment
# @exitcode 1 If age is not installed
# @example
#   decrypt_age_private_key
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

# @description Main entry point for the age private key decryption script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./age.sh
function main() {
    decrypt_age_private_key
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
