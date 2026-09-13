#!/usr/bin/env bats

# @file tests/install/rocky/server/setup_locale_unit.bats
# @brief Test Rocky Linux locale setup without systemd.

readonly SCRIPT_PATH="./install/rocky/server/setup_locale.sh"

function run_setup_locale() {
    local initial_content="${1:-}"
    local available_locale="${2:-en_US.UTF-8}"
    local config_state="${3:-present}"

    LOCALE_CONFIG_PATH="${BATS_TEST_TMPDIR}/locale.conf"
    CALLS_PATH="${BATS_TEST_TMPDIR}/setup_locale_calls.txt"
    if [ "${config_state}" = "missing" ]; then
        rm -f "${LOCALE_CONFIG_PATH}"
    else
        printf '%s' "${initial_content}" > "${LOCALE_CONFIG_PATH}"
    fi
    : > "${CALLS_PATH}"

    # shellcheck disable=SC2016
    run env \
        CALLS_PATH="${CALLS_PATH}" \
        AVAILABLE_LOCALE="${available_locale}" \
        DOTFILES_LOCALE_CONFIG_PATH="${LOCALE_CONFIG_PATH}" \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        bash -c '
            source "${SCRIPT_PATH}"

            locale() {
                printf "%s\n" "${AVAILABLE_LOCALE}"
            }

            sudo() {
                printf "%s\n" "$*" >> "${CALLS_PATH}"
                if [ "$1" = "--preserve-env=http_proxy,https_proxy,no_proxy" ]; then
                    return 0
                fi
                "$@"
            }

            main
        '
}

@test "[rocky-server] setup_locale leaves an existing LANG unchanged" {
    run_setup_locale $'LANG=en_US.UTF-8\n'
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run cat "${LOCALE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "LANG=en_US.UTF-8" ]
}

@test "[rocky-server] setup_locale writes LANG when it generates the locale" {
    run_setup_locale "" "C"
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"--preserve-env=http_proxy,https_proxy,no_proxy dnf install -y glibc-langpack-en"* ]]
    [[ "${output}" == *"install -m 0644 "* ]]

    run cat "${LOCALE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "LANG=en_US.UTF-8" ]
}

@test "[rocky-server] setup_locale configures LANG when the locale already exists" {
    run_setup_locale "" "en_US.UTF-8" "missing"
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"dnf install"* ]]
    [[ "${output}" == *"install -m 0644 "* ]]

    run cat "${LOCALE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "LANG=en_US.UTF-8" ]
}

@test "[rocky-server] setup_locale preserves other locale settings when updating LANG" {
    run_setup_locale $'LANG=C\nLC_TIME=ja_JP.UTF-8\n'
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *"dnf install"* ]]
    [[ "${output}" == *"install -m 0644 "* ]]

    run cat "${LOCALE_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'LANG=en_US.UTF-8\nLC_TIME=ja_JP.UTF-8' ]
}
