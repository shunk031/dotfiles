#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

BENCHMARK_RESULT_DIR="$(chezmoi source-path)/../benchmarks/results"
readonly BENCHMARK_RESULT_DIR

function prepare_benchmark() {
    find "${BENCHMARK_RESULT_DIR}" -type f -exec rm -f {} +
}

function get_os() {
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    echo -n "${os}"
}

function get_time_command() {
    case "$(get_os)" in
    darwin)
        echo -n "gtime"
        ;;
    linux)
        echo -n "time"
        ;;
    esac
}

function measure_initial_startup_time() {

    local result_file="${BENCHMARK_RESULT_DIR}/zsh-initial-startup-time.txt"

    local time_cmd
    time_cmd="$(get_time_command)"

    "${time_cmd}" --format="%e" --output="${result_file}" zsh -i -c exit
}

function measure_average_startup_time() {

    local result_file="${BENCHMARK_RESULT_DIR}/zsh-average-startup-time.txt"

    local time_cmd
    time_cmd="$(get_time_command)"

    for i in $(seq 1 10); do
        "${time_cmd}" --format="%e" --output="${BENCHMARK_RESULT_DIR}/zsh-average-startup-time-${i}.txt" zsh -i -c exit
    done
}

function record_startup_time() {

    local initial_file="${BENCHMARK_RESULT_DIR}/zsh-initial-startup-time.txt"
    local average_file="${BENCHMARK_RESULT_DIR}/zsh-average-startup-time-*.txt"

    initial_startup_time=$(cat "${initial_file}")
    # shellcheck disable=SC2086
    average_startup_time=$(cat ${average_file} | awk '{ total += $1 } END { print total/NR }')

    cat <<EOJ
[
    {
        "name": "zsh average startup time",
        "unit": "Second",
        "value": ${average_startup_time}
    },
    {
        "name": "zsh initial startup time",
        "unit": "Second",
        "value": ${initial_startup_time}
    }
]
EOJ

}

function main() {
    prepare_benchmark

    measure_initial_startup_time
    measure_average_startup_time

    record_startup_time
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
