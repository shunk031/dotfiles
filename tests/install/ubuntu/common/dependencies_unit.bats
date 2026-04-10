#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/dependencies.sh"

@test "[ubuntu-common] run_apt_get bootstraps sudo when missing" {
    local calls_path="${BATS_TEST_TMPDIR}/run_apt_get_calls.txt"
    : > "${calls_path}"

    run env CALLS_PATH="${calls_path}" bash -c '
        source "'"${SCRIPT_PATH}"'"

        command() {
            if [ "$1" = "-v" ] && [ "$2" = "sudo" ]; then
                return 1
            fi
            builtin command "$@"
        }

        apt-get() {
            echo "apt-get $*" >> "${CALLS_PATH}"
        }

        sudo() {
            echo "sudo $*" >> "${CALLS_PATH}"
        }

        run_apt_get install -y busybox
    '

    [ "${status}" -eq 0 ]

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"apt-get update"* ]]
    [[ "${output}" == *"apt-get install -y sudo"* ]]
    [[ "${output}" == *"sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y busybox"* ]]
}

@test "[ubuntu-common] install_apt_packages skips install when all commands exist" {
    local calls_path="${BATS_TEST_TMPDIR}/install_calls.txt"
    : > "${calls_path}"

    run env CALLS_PATH="${calls_path}" bash -c '
        source "'"${SCRIPT_PATH}"'"

        command() {
            if [ "$1" = "-v" ]; then
                return 0
            fi
            builtin command "$@"
        }

        run_apt_get() {
            echo "$*" >> "${CALLS_PATH}"
        }

        install_apt_packages
    '
    [ "${status}" -eq 0 ]

    [ ! -s "${calls_path}" ]
}

@test "[ubuntu-common] install_apt_packages installs when commands are missing" {
    local args_path="${BATS_TEST_TMPDIR}/install_args.txt"

    run env ARGS_PATH="${args_path}" DOTFILES_DEBUG= bash -c '
        source "'"${SCRIPT_PATH}"'"

        command() {
            if [ "$1" = "-v" ] && [ "$2" = "sudo" ]; then
                return 0
            fi
            if [ "$1" = "-v" ]; then
                return 1
            fi
            builtin command "$@"
        }

        run_apt_get() {
            echo "$*" > "${ARGS_PATH}"
        }

        install_apt_packages
    '
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == install\ -y* ]]
}

@test "[ubuntu-common] uninstall_apt_packages excludes sudo and git" {
    local args_path="${BATS_TEST_TMPDIR}/uninstall_args.txt"

    run env ARGS_PATH="${args_path}" bash -c '
        source "'"${SCRIPT_PATH}"'"

        run_apt_get() {
            echo "$*" > "${ARGS_PATH}"
        }

        uninstall_apt_packages
    '
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    actual_output="${output}"

    run bash -c '
        source "'"${SCRIPT_PATH}"'"

        removable_packages=()
        for package in "${PACKAGES[@]}"; do
            if [ "${package}" != "sudo" ] && [ "${package}" != "git" ]; then
                removable_packages+=("${package}")
            fi
        done

        printf "%s\n" "remove -y ${removable_packages[*]}"
    '
    [ "${status}" -eq 0 ]
    [ "${actual_output}" = "${output}" ]
}

@test "[ubuntu-common] script enables xtrace when DOTFILES_DEBUG is set" {
    run env DOTFILES_DEBUG=1 bash -c '
        source "'"${SCRIPT_PATH}"'"

        case "$-" in
            *x*)
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
    '

    [ "${status}" -eq 0 ]
}

@test "[ubuntu-common] install_apt_packages returns early in current shell when all commands exist" {
    source "${SCRIPT_PATH}"

    command() {
        if [ "$1" = "-v" ]; then
            return 0
        fi
        builtin command "$@"
    }

    CALLS_PATH="${BATS_TEST_TMPDIR}/install_no_missing_calls.txt"
    run_apt_get() {
        echo "$*" > "${CALLS_PATH}"
    }

    install_apt_packages

    [ ! -f "${CALLS_PATH}" ]
}
