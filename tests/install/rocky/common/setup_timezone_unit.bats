#!/usr/bin/env bats

# @file tests/install/rocky/common/setup_timezone_unit.bats
# @brief Test the Rocky Linux timezone setup without systemd.

readonly SCRIPT_PATH="./install/rocky/common/setup_timezone.sh"

function run_setup_timezone_with_stubs() {
    local timezone="${1:-Asia/Tokyo}"

    CALLS_PATH="${BATS_TEST_TMPDIR}/setup_timezone_calls.txt"
    LOCALTIME_PATH="${BATS_TEST_TMPDIR}/localtime"
    : > "${CALLS_PATH}"
    ln -s "/usr/share/zoneinfo/${timezone}" "${LOCALTIME_PATH}"

    # shellcheck disable=SC2016
    run env \
        CALLS_PATH="${CALLS_PATH}" \
        LOCALTIME_PATH="${LOCALTIME_PATH}" \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        DOTFILES_TIMEZONE="${timezone}" \
        bash -c '
            source "${SCRIPT_PATH}"

            readlink() {
                if [ "$1" = "-f" ] && [ "$2" = "/etc/localtime" ]; then
                    command readlink -f "${LOCALTIME_PATH}"
                else
                    command readlink "$@"
                fi
            }

            ln() {
                printf "ln %s\n" "$*" >> "${CALLS_PATH}"
            }

            cmp() {
                printf "cmp %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            timedatectl() {
                printf "timedatectl %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            sudo() {
                printf "sudo %s\n" "$*" >> "${CALLS_PATH}"
                if [ "$1" = "ln" ]; then
                    shift
                    ln "$@"
                fi
            }

            setup_timezone
        '
}

@test "[rocky-common] setup_timezone leaves the correct symlink unchanged" {
    run_setup_timezone_with_stubs
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "[rocky-common] setup_timezone replaces a different symlink" {
    CALLS_PATH="${BATS_TEST_TMPDIR}/setup_timezone_calls.txt"
    LOCALTIME_PATH="${BATS_TEST_TMPDIR}/localtime"
    : > "${CALLS_PATH}"
    ln -s /usr/share/zoneinfo/Etc/UTC "${LOCALTIME_PATH}"

    # shellcheck disable=SC2016
    run env \
        CALLS_PATH="${CALLS_PATH}" \
        LOCALTIME_PATH="${LOCALTIME_PATH}" \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        DOTFILES_TIMEZONE=Asia/Tokyo \
        bash -c '
            source "${SCRIPT_PATH}"

            readlink() {
                if [ "$1" = "-f" ] && [ "$2" = "/etc/localtime" ]; then
                    command readlink -f "${LOCALTIME_PATH}"
                else
                    command readlink "$@"
                fi
            }

            ln() {
                printf "ln %s\n" "$*" >> "${CALLS_PATH}"
            }

            cmp() {
                printf "cmp %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            timedatectl() {
                printf "timedatectl %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            sudo() {
                printf "sudo %s\n" "$*" >> "${CALLS_PATH}"
                if [ "$1" = "ln" ]; then
                    shift
                    ln "$@"
                fi
            }

            setup_timezone
        '
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"sudo ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime"* ]]
    [[ "${output}" == *"ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime"* ]]
    [[ "${output}" != *cmp* ]]
    [[ "${output}" != *timedatectl* ]]
}

@test "[rocky-common] setup_timezone resolves a copied timezone file" {
    CALLS_PATH="${BATS_TEST_TMPDIR}/setup_timezone_calls.txt"
    LOCALTIME_PATH="${BATS_TEST_TMPDIR}/localtime"
    : > "${CALLS_PATH}"
    cp /usr/share/zoneinfo/Etc/UTC "${LOCALTIME_PATH}"

    # shellcheck disable=SC2016
    run env \
        CALLS_PATH="${CALLS_PATH}" \
        LOCALTIME_PATH="${LOCALTIME_PATH}" \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        bash -c '
            source "${SCRIPT_PATH}"

            readlink() {
                if [ "$1" = "-f" ] && [ "$2" = "/etc/localtime" ]; then
                    command readlink -f "${LOCALTIME_PATH}"
                else
                    command readlink "$@"
                fi
            }

            ln() {
                printf "ln %s\n" "$*" >> "${CALLS_PATH}"
            }

            cmp() {
                printf "cmp %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            timedatectl() {
                printf "timedatectl %s\n" "$*" >> "${CALLS_PATH}"
                return 1
            }

            sudo() {
                printf "sudo %s\n" "$*" >> "${CALLS_PATH}"
                if [ "$1" = "ln" ]; then
                    shift
                    ln "$@"
                fi
            }

            setup_timezone
        '
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"sudo ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime"* ]]
    [[ "${output}" == *"ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime"* ]]
    [[ "${output}" != *cmp* ]]
    [[ "${output}" != *timedatectl* ]]
}
