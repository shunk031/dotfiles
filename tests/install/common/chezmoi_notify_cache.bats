#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_chezmoi-notify-cache"
readonly RUN_AFTER_TEMPLATE="./home/.chezmoiscripts/common/run_after_99-refresh-chezmoi-notify-cache.sh.tmpl"
readonly P10K_CONFIG_PATH="./home/dot_config/powerlevel10k/p10k.zsh"
readonly STARSHIP_CONFIG_PATH="./home/dot_config/starship.toml"

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

function notify_cache_dir() {
    printf "%s\n" "${XDG_CACHE_HOME:-${HOME}/.cache}/chezmoi-notify"
}

function notify_count_file() {
    printf "%s\n" "$(notify_cache_dir)/count"
}

function notify_last_check_file() {
    printf "%s\n" "$(notify_cache_dir)/last_check"
}

function expected_refresh_calls() {
    printf "git -- fetch -q\ngit -- rev-list --count HEAD..origin/master"
}

@test "[common] refresh clears caches when the dotfiles repo is already up to date" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=0

    local cache_dir
    local p10k_dir
    local starship_dir

    cache_dir="$(notify_cache_dir)"
    p10k_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-chezmoi"
    starship_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/starship-chezmoi"
    mkdir -p "${cache_dir}" "${p10k_dir}" "${starship_dir}"
    printf "9\n" > "$(notify_count_file)"
    printf "9\n" > "${p10k_dir}/status"
    printf "9\n" > "${starship_dir}/count"
    printf "42\n" > "${p10k_dir}/last_check"
    printf "42\n" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ ! -e "$(notify_count_file)" ]
    [ -s "$(notify_last_check_file)" ]
    [ ! -e "${p10k_dir}/status" ]
    [ ! -e "${p10k_dir}/last_check" ]
    [ ! -e "${starship_dir}/count" ]
    [ ! -e "${starship_dir}/last_check" ]

    local last_check
    last_check="$(< "$(notify_last_check_file)")"
    [[ "${last_check}" =~ ^[0-9]+$ ]]
    [ "${last_check}" -gt 1 ]
}

@test "[common] refresh writes the shared count under XDG_CACHE_HOME and removes legacy caches" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=3
    export XDG_CACHE_HOME="${BATS_TEST_TMPDIR}/xdg-cache"

    local p10k_dir
    local starship_dir

    p10k_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-chezmoi"
    starship_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/starship-chezmoi"
    mkdir -p "${p10k_dir}" "${starship_dir}"
    printf "11\n" > "${p10k_dir}/status"
    printf "11\n" > "${starship_dir}/count"
    printf "11\n" > "${p10k_dir}/last_check"
    printf "11\n" > "${starship_dir}/last_check"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ -s "$(notify_count_file)" ]
    [ -s "$(notify_last_check_file)" ]
    [ ! -e "${p10k_dir}/status" ]
    [ ! -e "${p10k_dir}/last_check" ]
    [ ! -e "${starship_dir}/count" ]
    [ ! -e "${starship_dir}/last_check" ]

    local count
    count="$(< "$(notify_count_file)")"
    [ "${count}" = "3" ]
    [ "$(< "${CHEZMOI_CALLS_PATH}")" = "$(expected_refresh_calls)" ]
}

@test "[common] refresh leaves existing caches untouched when upstream fetch fails" {
    write_chezmoi_stub
    export CHEZMOI_SHOULD_FAIL=1

    local cache_dir

    cache_dir="$(notify_cache_dir)"
    mkdir -p "${cache_dir}"
    printf "7\n" > "$(notify_count_file)"
    printf "42\n" > "$(notify_last_check_file)"

    run bash "${SCRIPT_PATH}" refresh
    [ "${status}" -eq 0 ]
    [ "$(< "$(notify_count_file)")" = "7" ]
    [ "$(< "$(notify_last_check_file)")" = "42" ]
    [ "$(< "${CHEZMOI_CALLS_PATH}")" = "git -- fetch -q" ]
}

@test "[common] refresh-if-stale skips recomputation while the shared cache is fresh" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=5

    local now

    now="$(date +%s)"
    mkdir -p "$(notify_cache_dir)"
    printf "%s\n" "${now}" > "$(notify_last_check_file)"

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ ! -e "${CHEZMOI_CALLS_PATH}" ]
    [ ! -e "$(notify_count_file)" ]
}

@test "[common] refresh-if-stale recomputes when the shared last_check file is missing" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=4

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ "$(< "$(notify_count_file)")" = "4" ]
    [ "$(< "${CHEZMOI_CALLS_PATH}")" = "$(expected_refresh_calls)" ]
}

@test "[common] refresh-if-stale recomputes when the shared last_check file is expired" {
    write_chezmoi_stub
    export CHEZMOI_REV_LIST_COUNT=6

    local now
    local expired

    now="$(date +%s)"
    expired="$((now - 4000))"
    mkdir -p "$(notify_cache_dir)"
    printf "%s\n" "${expired}" > "$(notify_last_check_file)"

    run bash "${SCRIPT_PATH}" refresh-if-stale
    [ "${status}" -eq 0 ]
    [ "$(< "$(notify_count_file)")" = "6" ]
    [ -s "${CHEZMOI_CALLS_PATH}" ]
}

@test "[common] run_after template invokes the helper with an absolute refresh command" {
    [ -f "${RUN_AFTER_TEMPLATE}" ]

    run grep -F '"${HOME}/.local/bin/common/chezmoi-notify-cache" refresh' "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]
}

@test "[common] p10k reads the same chezmoi cache file as starship" {
    [ -f "${P10K_CONFIG_PATH}" ]
    [ -f "${STARSHIP_CONFIG_PATH}" ]

    run grep -F 'command = "cat ${XDG_CACHE_HOME:-$HOME/.cache}/chezmoi-notify/count"' "${STARSHIP_CONFIG_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'local count_file="${XDG_CACHE_HOME:-$HOME/.cache}/chezmoi-notify/count"' "${P10K_CONFIG_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'if [[ -s "$count_file" ]]; then' "${P10K_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
}
