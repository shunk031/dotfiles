#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/setup_timezone.sh"

function run_setup_timezone_with_stubs() {
    local timezone="${1:-Asia/Tokyo}"

    CALLS_PATH="${BATS_TEST_TMPDIR}/setup_timezone_calls.txt"
    TIMEZONE_PATH="${BATS_TEST_TMPDIR}/timezone"
    : > "${CALLS_PATH}"

    # shellcheck disable=SC2016
    run env \
        CALLS_PATH="${CALLS_PATH}" \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        TIMEZONE_PATH="${TIMEZONE_PATH}" \
        DOTFILES_TIMEZONE="${timezone}" \
        bash -c '
            source "${SCRIPT_PATH}"

            sudo() {
                printf "sudo %s\n" "$*" >> "${CALLS_PATH}"

                if [ "$1" = "tee" ] && [ "$2" = "/etc/timezone" ]; then
                    cat > "${TIMEZONE_PATH}"
                fi
            }

            setup_timezone
        '
}

@test "[ubuntu-common] setup_timezone configures Asia/Tokyo non-interactively" {
    run_setup_timezone_with_stubs
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"sudo ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime"* ]]
    [[ "${output}" == *"sudo --preserve-env=http_proxy,https_proxy,no_proxy DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo apt-get install -y --no-install-recommends tzdata"* ]]
    [[ "${output}" == *"sudo DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo dpkg-reconfigure -f noninteractive tzdata"* ]]

    run cat "${TIMEZONE_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Asia/Tokyo" ]
}

@test "[ubuntu-common] setup_timezone allows DOTFILES_TIMEZONE override" {
    run_setup_timezone_with_stubs "Etc/UTC"
    [ "${status}" -eq 0 ]

    run cat "${CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"sudo ln -snf /usr/share/zoneinfo/Etc/UTC /etc/localtime"* ]]
    [[ "${output}" == *"TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata"* ]]
    [[ "${output}" == *"TZ=Etc/UTC dpkg-reconfigure -f noninteractive tzdata"* ]]

    run cat "${TIMEZONE_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Etc/UTC" ]
}
