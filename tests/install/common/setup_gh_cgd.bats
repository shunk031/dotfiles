#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_setup-gh-cgd"

function setup() {
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export GH_CALLS_PATH="${BATS_TEST_TMPDIR}/gh_calls.txt"
    export GH_LOGIN_STATE_PATH="${BATS_TEST_TMPDIR}/gh_login_state"
    export GH_STUB_ACTIVE_USER="shunk031"
    export GH_STUB_CGD_LOGIN="creative-graphic-design-dev"
    PATH="${TEST_BIN_DIR}:$(getconf PATH)"
    export PATH

    mkdir -p "${TEST_BIN_DIR}"
    rm -f "${GH_CALLS_PATH}" "${GH_LOGIN_STATE_PATH}"
    write_gh_stub
}

function write_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf '%s|GH_TOKEN=%s\n' "$*" "${GH_TOKEN:-}" >> "${GH_CALLS_PATH}"

case "$*" in
    "auth token --hostname github.com --user creative-graphic-design-dev")
        if [ -e "${GH_LOGIN_STATE_PATH}" ]; then
            printf 'cgd-token\n'
        else
            exit 1
        fi
        ;;
    "api user --jq .login")
        if [ "${GH_TOKEN:-}" = "cgd-token" ]; then
            printf '%s\n' "${GH_STUB_CGD_LOGIN}"
        else
            printf '%s\n' "${GH_STUB_ACTIVE_USER}"
        fi
        ;;
    "auth login --hostname github.com --git-protocol https --web")
        touch "${GH_LOGIN_STATE_PATH}"
        ;;
    "auth switch --hostname github.com --user "*)
        ;;
    *)
        exit 1
        ;;
esac
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

@test "[common] setup-gh-cgd logs in and restores the previous active account" {
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Authenticated creative-graphic-design-dev"* ]]
    grep -Fx 'auth login --hostname github.com --git-protocol https --web|GH_TOKEN=' "${GH_CALLS_PATH}"
    grep -Fx 'api user --jq .login|GH_TOKEN=cgd-token' "${GH_CALLS_PATH}"
    grep -Fx 'auth switch --hostname github.com --user shunk031|GH_TOKEN=' "${GH_CALLS_PATH}"
}

@test "[common] setup-gh-cgd reuses an existing stored account" {
    touch "${GH_LOGIN_STATE_PATH}"

    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"already authenticated"* ]]
    ! grep -Fq 'auth login' "${GH_CALLS_PATH}"
    ! grep -Fq 'auth switch' "${GH_CALLS_PATH}"
}

@test "[common] setup-gh-cgd rejects the wrong authenticated identity" {
    touch "${GH_LOGIN_STATE_PATH}"
    export GH_STUB_CGD_LOGIN="shunk031"

    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Expected GitHub account creative-graphic-design-dev, got shunk031"* ]]
}
