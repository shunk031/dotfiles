#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function prepare_benchmark() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    echo "make temp directory to ${tmp_dir}" >&2
    echo -n "${tmp_dir}"
}

function cleanup_result_dir() {
    local target_dir=$1
    echo "cleanup ${target_dir}" >&2
    rm -rf "${target_dir}"
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
    local benchmark_result_dir=$1
    local result_file="${benchmark_result_dir}/zsh-initial-startup-time.txt"

    local time_cmd
    time_cmd="$(get_time_command)"

    "${time_cmd}" --format="%e" --output="${result_file}" zsh -i -c exit
}

function measure_average_startup_time() {
    local benchmark_result_dir=$1

    local result_file="${benchmark_result_dir}/zsh-average-startup-time.txt"

    local time_cmd
    time_cmd="$(get_time_command)"

    for i in $(seq 1 10); do
        "${time_cmd}" --format="%e" --output="${benchmark_result_dir}/zsh-average-startup-time-${i}.txt" zsh -i -c exit
    done
}

function record_startup_time() {
    local benchmark_result_dir=$1

    local initial_file="${benchmark_result_dir}/zsh-initial-startup-time.txt"
    local average_file="${benchmark_result_dir}/zsh-average-startup-time-*.txt"

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
    local tmp_dir
    tmp_dir=$(prepare_benchmark)

    measure_initial_startup_time "${tmp_dir}"
    measure_average_startup_time "${tmp_dir}"

    record_startup_time "${tmp_dir}"
    cleanup_result_dir "${tmp_dir}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
