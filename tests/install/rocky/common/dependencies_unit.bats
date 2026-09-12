#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/rocky/common/dependencies.sh"

@test "[rocky-common] install_dnf_packages installs missing command packages as root" {
    run bash -c '
        source "$1"

        function command() {
            [ "$2" != "cmake" ]
        }
        function dnf() {
            printf "dnf %s\n" "$*"
        }
        function sudo() {
            printf "unexpected sudo call\n" >&2
            return 1
        }

        install_dnf_packages
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [[ "${output}" == *"dnf install -y cmake"* ]]
    [ "${output}" = "dnf install -y cmake" ]
}

@test "[rocky-common] run_dnf uses sudo for non-root callers" {
    run setpriv --reuid 65534 --regid 65534 --clear-groups bash -c '
        source "$1"

        function dnf() {
            printf "unexpected dnf call\n" >&2
            return 1
        }
        function sudo() {
            printf "sudo %s\n" "$*"
        }

        run_dnf install -y cmake
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [[ "${output}" == *"sudo --preserve-env=http_proxy,https_proxy,no_proxy dnf install -y cmake"* ]]
    [[ "${output}" != *"unexpected dnf call"* ]]
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

@test "[rocky-common] install_dnf_packages installs the terminal pinentry package when missing" {
    run bash -c '
        source "$1"

        function command() {
            [ "$2" != "pinentry-curses" ]
        }
        function dnf() {
            printf "dnf %s\n" "$*"
        }
        function sudo() {
            printf "unexpected sudo call\n" >&2
            return 1
        }

        install_dnf_packages
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [[ "${output}" == *"dnf install -y pinentry"* ]]
}

@test "[rocky-common] dependency packages use Rocky names" {
    run grep -F 'ip:iproute' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'ping:iputils' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'gpg:gnupg2' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'pinentry-curses:pinentry' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'cmp:diffutils' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'gcc:gcc' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'g++:gcc-c++' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'make:make' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
}
