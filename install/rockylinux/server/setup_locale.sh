#!/usr/bin/env bash

# @file install/rockylinux/server/setup_locale.sh
# @brief Ensure the preferred locale exists on Rocky Linux servers.
# @description
#   Installs the English locale package when needed and rewrites the system
#   locale configuration without requiring systemd's `localectl` service.

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
# @description Rewrite the locale configuration with LANG replaced or appended while preserving other entries.
#
function configure_locale() {
    local content

    if [ -f "${LOCALE_CONFIG_PATH}" ]; then
        content="$(awk -v target="LANG=${TARGET}" '
            /^LANG=/ {
                if (!replaced) {
                    print target
                    replaced = 1
                }
                next
            }

            { print }

            END {
                if (!replaced) {
                    print target
                }
            }
        ' "${LOCALE_CONFIG_PATH}")"
    else
        content="LANG=${TARGET}"
    fi

    printf '%s\n' "${content}" | sudo tee "${LOCALE_CONFIG_PATH}" > /dev/null
}

#
# @description Check whether the target locale is already generated.
# @exitcode 0 When the target locale is available.
# @exitcode 1 When the target locale is unavailable.
#
function locale_is_available() {
    local available_locale target_normalized

    target_normalized="$(normalize_locale "${TARGET}")"
    while IFS= read -r available_locale; do
        if [ "$(normalize_locale "${available_locale}")" = "${target_normalized}" ]; then
            return 0
        fi
    done < <(locale -a 2> /dev/null)

    return 1
}

#
# @description Install and configure the target locale when needed.
#
function main() {
    if locale_is_available; then
        printf '%s already exists.\n' "${TARGET}"
    else
        sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y glibc-langpack-en
    fi

    if ! locale_is_configured; then
        configure_locale
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
