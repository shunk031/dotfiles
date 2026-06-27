#!/usr/bin/env bats

# shellcheck disable=SC2030,SC2031

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_update-dotfiles"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export CHEZMOI_CALLS_PATH="${BATS_TEST_TMPDIR}/chezmoi_calls.txt"
    export GH_CALLS_PATH="${BATS_TEST_TMPDIR}/gh_calls.txt"
    export PUBLIC_BRANCH="main"
    export PRIVATE_BRANCH="main"
    export PUBLIC_STATUS=""
    export PRIVATE_STATUS=""
    export PUBLIC_LOCAL_REV="local"
    export PUBLIC_REMOTE_REV="local"
    export PUBLIC_BASE_REV="local"
    export PRIVATE_LOCAL_REV="private-local"
    export PRIVATE_REMOTE_REV="private-local"
    export PRIVATE_BASE_REV="private-local"
    PATH="${TEST_BIN_DIR}:$(getconf PATH)"
    export PATH

    mkdir -p "${HOME}" "${TEST_BIN_DIR}"
    rm -f "${CHEZMOI_CALLS_PATH}" "${GH_CALLS_PATH}"
    unset GITHUB_TOKEN

    write_chezmoi_stub
    write_gh_stub
}

function write_chezmoi_stub() {
    cat > "${TEST_BIN_DIR}/chezmoi" << 'EOF'
#!/usr/bin/env bash

source_name="public"
if [[ "${1:-}" == "--source" ]]; then
    source_name="private"
    shift 4
fi

printf "%s:%s\n" "${source_name}" "$*" >> "${CHEZMOI_CALLS_PATH}"

if [[ "${1:-}" == "git" && "${2:-}" == "--" ]]; then
    shift 2
    case "$1" in
    rev-parse)
        if [[ "$2" == "--abbrev-ref" ]]; then
            if [[ "${source_name}" == "public" ]]; then
                printf "%s\n" "${PUBLIC_BRANCH}"
            else
                printf "%s\n" "${PRIVATE_BRANCH}"
            fi
        elif [[ "$2" == "HEAD" ]]; then
            if [[ "${source_name}" == "public" ]]; then
                printf "%s\n" "${PUBLIC_LOCAL_REV}"
            else
                printf "%s\n" "${PRIVATE_LOCAL_REV}"
            fi
        elif [[ "$2" == "origin/main" ]]; then
            if [[ "${source_name}" == "public" ]]; then
                printf "%s\n" "${PUBLIC_REMOTE_REV}"
            else
                printf "%s\n" "${PRIVATE_REMOTE_REV}"
            fi
        fi
        ;;
    status)
        if [[ "${source_name}" == "public" ]]; then
            printf "%s\n" "${PUBLIC_STATUS}"
        else
            printf "%s\n" "${PRIVATE_STATUS}"
        fi
        ;;
    merge-base)
        if [[ "${source_name}" == "public" ]]; then
            printf "%s\n" "${PUBLIC_BASE_REV}"
        else
            printf "%s\n" "${PRIVATE_BASE_REV}"
        fi
        ;;
    fetch | merge)
        ;;
    esac
fi
EOF

    chmod +x "${TEST_BIN_DIR}/chezmoi"
}

function write_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${GH_CALLS_PATH}"
printf "stub-token\n"
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

function expected_up_to_date_public_calls() {
    cat << 'EOF'
public:git -- rev-parse --abbrev-ref HEAD
public:git -- status --porcelain
public:git -- fetch --prune origin
public:git -- rev-parse HEAD
public:git -- rev-parse origin/main
public:git -- merge-base HEAD origin/main
public:apply --verbose
EOF
}

@test "[common] default target updates and applies public then private" {
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Updating public chezmoi source..."* ]]
    [[ "${output}" == *"Updating private chezmoi source..."* ]]
    [ "$(head -n 7 "${CHEZMOI_CALLS_PATH}")" = "$(expected_up_to_date_public_calls)" ]
    [ "$(grep -c '^private:' "${CHEZMOI_CALLS_PATH}")" -eq 7 ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}

@test "[common] public target only updates and applies public source" {
    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 0 ]
    [ "$(< "${CHEZMOI_CALLS_PATH}")" = "$(expected_up_to_date_public_calls)" ]
}

@test "[common] private target uses explicit private source and config" {
    run bash "${SCRIPT_PATH}" private
    [ "${status}" -eq 0 ]
    [ "$(grep -c '^private:' "${CHEZMOI_CALLS_PATH}")" -eq 7 ]
    [ "$(grep -c '^public:' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
}

@test "[common] dirty source stops before fetch and apply" {
    export PUBLIC_STATUS=" M home/dot_zshrc"

    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"has uncommitted changes"* ]]
    [ "$(grep -c 'fetch --prune origin' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
    [ "$(grep -c 'apply --verbose' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
}

@test "[common] non-main branch stops before fetch and apply" {
    export PUBLIC_BRANCH="feat/work"

    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"expected main"* ]]
    [ "$(grep -c 'fetch --prune origin' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
    [ "$(grep -c 'apply --verbose' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
}

@test "[common] local-ahead source stops instead of applying" {
    export PUBLIC_LOCAL_REV="local-ahead"
    export PUBLIC_REMOTE_REV="remote"
    export PUBLIC_BASE_REV="remote"

    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"ahead of or diverged"* ]]
    [ "$(grep -c 'merge --ff-only origin/main' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
    [ "$(grep -c 'apply --verbose' "${CHEZMOI_CALLS_PATH}")" -eq 0 ]
}

@test "[common] fast-forward source merges before applying" {
    export PUBLIC_LOCAL_REV="old"
    export PUBLIC_REMOTE_REV="new"
    export PUBLIC_BASE_REV="old"

    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 0 ]
    run grep -F 'public:git -- merge --ff-only origin/main' "${CHEZMOI_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    run tail -n 1 "${CHEZMOI_CALLS_PATH}"
    [ "${output}" = "public:apply --verbose" ]
}

@test "[common] existing GITHUB_TOKEN is reused" {
    export GITHUB_TOKEN="existing-token"

    run bash "${SCRIPT_PATH}" public
    [ "${status}" -eq 0 ]
    [ ! -e "${GH_CALLS_PATH}" ]
}

@test "[common] invalid target prints usage" {
    run bash "${SCRIPT_PATH}" nope
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"usage: update-dotfiles [all|public|private]"* ]]
}
