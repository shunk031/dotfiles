#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/rocky/common/dependencies.sh"

@test "[rocky-common] install_dnf_packages installs missing command packages" {
    run bash -c '
        source "$1"

        function command() {
            [ "$2" != "tmux" ]
        }
        function sudo() {
            printf "%s\n" "$*"
        }

        install_dnf_packages
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [[ "${output}" == *"dnf install -y tmux"* ]]
}

@test "[rocky-common] install_dnf_packages skips dnf when commands exist" {
    run bash -c '
        source "$1"

        function command() {
            return 0
        }
        function sudo() {
            return 99
        }

        install_dnf_packages
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "[rocky-common] dependency packages use Rocky names" {
    run grep -F 'ip:iproute' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'ping:iputils' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'gpg:gnupg2' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
}
