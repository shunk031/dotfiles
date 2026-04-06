#!/usr/bin/env bash

set -Eeuo pipefail

function kcov_options() {
    local -a options=()

    if [ "${OS}" == "macos-14" ]; then
        options+=("--bash-parser=/bin/bash")
        options+=("--bash-parse-files-in-dir=${PWD}")
    fi

    printf '%s\n' "${options[@]}"
}

function run_common_test() {
    local -a options=()
    while IFS= read -r option; do
        if [ -n "${option}" ]; then
            options+=("${option}")
        fi
    done < <(kcov_options)

    kcov --clean \
        "${options[@]}" \
        "./coverage_common" \
        bats -r "tests/install/common/"
}

function run_os_specific_test() {
    local -a options=()
    while IFS= read -r option; do
        if [ -n "${option}" ]; then
            options+=("${option}")
        fi
    done < <(kcov_options)

    if [ "${OS}" == "macos-14" ]; then
        kcov --clean \
            "${options[@]}" \
            "./coverage_macos_common" \
            bats -r "tests/install/macos/common/"

    elif [ "${OS}" == "ubuntu-latest" ]; then
        kcov --clean \
            "${options[@]}" \
            "./coverage_ubuntu_common" \
            bats -r "tests/install/ubuntu/common/"
    else
        echo "${OS} and ${SYSTEM} are not supported" >&2
        exit 1
    fi
}

function merge_coverage_results() {
    if [ "${OS}" == "macos-14" ]; then
        kcov --merge "./coverage" \
            "./coverage_common" \
            "./coverage_macos_common"

    elif [ "${OS}" == "ubuntu-latest" ]; then
        kcov --merge ./coverage \
            "./coverage_common" \
            "./coverage_ubuntu_common" \
            "./coverage_ubuntu_${SYSTEM}"
    else
        echo "${OS} and ${SYSTEM} are not supported" >&2
        exit 1
    fi
}

function main() {
    run_common_test
    run_os_specific_test
    merge_coverage_results
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
