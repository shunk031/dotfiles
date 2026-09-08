#!/usr/bin/env bash

# @file install/rocky/server/setup_locale.sh
# @brief Ensure the preferred locale exists on Rocky Linux servers.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TARGET="en_US.UTF-8"

#
# @description Normalize a locale name for punctuation-insensitive comparison.
# @arg $1 string Locale name.
# @stdout Lowercase locale name without punctuation.
#
function normalize_locale() {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '_.-'
}

#
# @description Install and select the target locale when it is unavailable.
#
function main() {
    local available_locale target_normalized

    target_normalized="$(normalize_locale "${TARGET}")"
    while IFS= read -r available_locale; do
        if [ "$(normalize_locale "${available_locale}")" = "${target_normalized}" ]; then
            printf '%s already exists.\n' "${TARGET}"
            return 0
        fi
    done < <(locale -a 2> /dev/null)

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y glibc-langpack-en
    sudo localectl set-locale "LANG=${TARGET}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
