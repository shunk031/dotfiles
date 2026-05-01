#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_chezmoi-notify-cache"
readonly RUN_AFTER_TEMPLATE="./home/.chezmoiscripts/common/run_after_99-refresh-chezmoi-notify-cache.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export CHEZMOI_CALLS_PATH="${BATS_TEST_TMPDIR}/chezmoi_calls.txt"
    export PATH="${TEST_BIN_DIR}:$(getconf PATH)"

    mkdir -p "${HOME}" "${TEST_BIN_DIR}"
    rm -f "${CHEZMOI_CALLS_PATH}"
    unset XDG_CACHE_HOME
    unset CHEZMOI_REV_LIST_COUNT
    unset CHEZMOI_SHOULD_FAIL
}

function write_chezmoi_stub() {
    cat > "${TEST_BIN_DIR}/chezmoi" << 'EOF'
#!/usr/bin/env bash

if [ -n "${CHEZMOI_CALLS_PATH:-}" ]; then
    printf "%s\n" "$*" >> "${CHEZMOI_CALLS_PATH}"
fi

if [ "${CHEZMOI_SHOULD_FAIL:-0}" = "1" ]; then
    exit 1
fi

printf "%s\n" "${CHEZMOI_REV_LIST_COUNT:-0}"
EOF

    chmod +x "${TEST_BIN_DIR}/chezmoi"
}

function p10k_cache_dir() {
    printf "%s\n" "${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-chezmoi"
}

function starship_cache_dir() {
    printf "%s\n" "${XDG_CACHE_HOME:-${HOME}/.cache}/starship-chezmoi"
}

@test "[common] refresh clears caches when the dotfiles repo is already up to date" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=0

    local p10k_dir
    local starship_dir

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "9\n" > "${p10k_dir}/status"
    printf "9\n" > "${starship_dir}/count"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ ! -e "${p10k_dir}/status" ]
    [ ! -e "${starship_dir}/count" ]
    [ -s "${p10k_dir}/last_check" ]
    [ -s "${starship_dir}/last_check" ]

    local p10k_last_check
    local starship_last_check
    p10k_last_check="$(< "${p10k_dir}/last_check")"
    starship_last_check="$(< "${starship_dir}/last_check")"
    [[ "${p10k_last_check}" =~ ^[0-9]+$ ]]
    [[ "${starship_last_check}" =~ ^[0-9]+$ ]]
    [ "${p10k_last_check}" = "${starship_last_check}" ]
    [ "${p10k_last_check}" -gt 1 ]
    [ "${starship_last_check}" -gt 1 ]
}

@test "[common] refresh writes the same count into both caches under XDG_CACHE_HOME" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=3
    export XDG_CACHE_HOME="${BATS_TEST_TMPDIR}/xdg-cache"

    local p10k_dir
    local starship_dir

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ -s "${p10k_dir}/status" ]
    [ -s "${starship_dir}/count" ]

    local p10k_count
    local starship_count
    p10k_count="$(< "${p10k_dir}/status")"
    starship_count="$(< "${starship_dir}/count")"
    [ "${p10k_count}" = "3" ]
    [ "${starship_count}" = "3" ]
    [ -s "${p10k_dir}/last_check" ]
    [ -s "${starship_dir}/last_check" ]
    [ "$(< "${CHEZMOI_CALLS_PATH}")" = "git -- rev-list --count HEAD..origin/master" ]
}

@test "[common] refresh leaves existing caches untouched when chezmoi rev-list fails" {
    write_chezmoi_stub
    export CHEZMOI_SHOULD_FAIL=1

    local p10k_dir
    local starship_dir

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "7\n" > "${p10k_dir}/status"
    printf "7\n" > "${starship_dir}/count"
    printf "42\n" > "${p10k_dir}/last_check"
    printf "42\n" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ "$(< "${p10k_dir}/status")" = "7" ]
    [ "$(< "${starship_dir}/count")" = "7" ]
    [ "$(< "${p10k_dir}/last_check")" = "42" ]
    [ "$(< "${starship_dir}/last_check")" = "42" ]
}

@test "[common] refresh-if-stale skips recomputation while both caches are fresh" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=5

    local p10k_dir
    local starship_dir
    local now

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"
    now="$(date +%s)"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "%s\n" "${now}" > "${p10k_dir}/last_check"
    printf "%s\n" "${now}" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ ! -e "${CHEZMOI_CALLS_PATH}" ]
    [ ! -e "${p10k_dir}/status" ]
    [ ! -e "${starship_dir}/count" ]
}

@test "[common] refresh-if-stale recomputes when either last_check file is missing" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=4

    local p10k_dir
    local starship_dir
    local now

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"
    now="$(date +%s)"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "%s\n" "${now}" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ "$(< "${p10k_dir}/status")" = "4" ]
    [ "$(< "${starship_dir}/count")" = "4" ]
    [ -s "${CHEZMOI_CALLS_PATH}" ]
}

@test "[common] refresh-if-stale recomputes when either last_check file is expired" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=6

    local p10k_dir
    local starship_dir
    local now
    local expired

    p10k_dir="$(p10k_cache_dir)"
    starship_dir="$(starship_cache_dir)"
    now="$(date +%s)"
    expired="$((now - 4000))"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "%s\n" "${expired}" > "${p10k_dir}/last_check"
    printf "%s\n" "${now}" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ "$(< "${p10k_dir}/status")" = "6" ]
    [ "$(< "${starship_dir}/count")" = "6" ]
    [ -s "${CHEZMOI_CALLS_PATH}" ]
}

@test "[common] run_after template invokes the helper with an absolute refresh command" {
    [ -f "${RUN_AFTER_TEMPLATE}" ]

    run grep -F '"${HOME}/.local/bin/common/chezmoi-notify-cache" refresh' "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]
}
