#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/dependencies.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    unset -f command || true
    unset -f apt-get || true
    unset -f sudo || true
    unset -f run_apt_get || true
}

@test "[ubuntu-common] run_apt_get bootstraps sudo when missing" {
    local calls_path="${BATS_TEST_TMPDIR}/run_apt_get_calls.txt"
    : > "${calls_path}"

    function command() {
        if [ "$1" = "-v" ] && [ "$2" = "sudo" ]; then
            return 1
        fi
        builtin command "$@"
    }

    function apt-get() {
        echo "apt-get $*" >> "${calls_path}"
    }

    function sudo() {
        echo "sudo $*" >> "${calls_path}"
    }

    run_apt_get install -y busybox

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"apt-get update"* ]]
    [[ "${output}" == *"apt-get install -y sudo"* ]]
    [[ "${output}" == *"sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y busybox"* ]]
}

@test "[ubuntu-common] install_apt_packages skips install when all commands exist" {
    local calls_path="${BATS_TEST_TMPDIR}/install_calls.txt"
    : > "${calls_path}"

    function command() {
        if [ "$1" = "-v" ]; then
            return 0
        fi
        builtin command "$@"
    }

    function run_apt_get() {
        echo "$*" >> "${calls_path}"
    }

    run install_apt_packages
    [ "${status}" -eq 0 ]

    run wc -l "${calls_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == 0* ]]
}

@test "[ubuntu-common] uninstall_apt_packages excludes sudo and git" {
    local args_path="${BATS_TEST_TMPDIR}/uninstall_args.txt"

    function run_apt_get() {
        echo "$*" > "${args_path}"
    }

    run uninstall_apt_packages
    [ "${status}" -eq 0 ]

    run cat "${args_path}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == remove\ -y* ]]
    [[ " ${output} " != *" sudo "* ]]
    [[ " ${output} " != *" git "* ]]
    [[ " ${output} " == *" busybox "* ]]
}
