#!/usr/bin/env bash

# @file install/rocky/server/setup_locale.sh
# @brief Ensure the preferred locale exists on Rocky Linux servers.
# @description
#   Installs the English locale package when needed and writes the system locale
#   configuration without requiring systemd's `localectl` service.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TARGET="en_US.UTF-8"
readonly LOCALE_CONFIG_PATH="${DOTFILES_LOCALE_CONFIG_PATH:-/etc/locale.conf}"

#
# @description Normalize a locale name for punctuation-insensitive comparison.
# @arg $1 string Locale name.
# @stdout Lowercase locale name without punctuation.
#
function normalize_locale() {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '_.-'
}

#
# @description Check whether the target locale is already configured.
# @exitcode 0 When `/etc/locale.conf` already sets the target locale.
# @exitcode 1 When the target locale is not configured.
#
function locale_is_configured() {
    [ -f "${LOCALE_CONFIG_PATH}" ] &&
        grep -qxF "LANG=${TARGET}" "${LOCALE_CONFIG_PATH}"
}

#
# @description Write the target locale directly without requiring systemd.
#
function configure_locale() {
    printf 'LANG=%s\n' "${TARGET}" | sudo tee "${LOCALE_CONFIG_PATH}" > /dev/null
}

#
# @description Install and select the target locale when it is unavailable.
#
function main() {
    local available_locale target_normalized

    if locale_is_configured; then
        return 0
    fi

    target_normalized="$(normalize_locale "${TARGET}")"
    while IFS= read -r available_locale; do
        if [ "$(normalize_locale "${available_locale}")" = "${target_normalized}" ]; then
            printf '%s already exists.\n' "${TARGET}"
            return 0
        fi
    done < <(locale -a 2> /dev/null)

    sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y glibc-langpack-en
    configure_locale
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
