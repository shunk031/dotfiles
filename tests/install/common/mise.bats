#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"
readonly TMPL_SCRIPT_GLOB="./home/.chezmoiscripts/common/run_once_after_*-install-mise.sh.tmpl"
readonly RUN_AFTER_TEMPLATE="./home/.chezmoiscripts/common/run_after_20-install-mise-tools.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_calls.txt"
    export GH_CALLS_PATH="${BATS_TEST_TMPDIR}/gh_calls.txt"
    PATH="${TEST_BIN_DIR}:$(getconf PATH)"
    export PATH

    mkdir -p "${HOME}/.local/bin" "${TEST_BIN_DIR}"
    rm -f "${MISE_CALLS_PATH}" "${GH_CALLS_PATH}"
    unset GITHUB_TOKEN

    source "${SCRIPT_PATH}"
}

function teardown() {
    if [ -e "${MISE_INSTALL_PATH}" ]; then
        uninstall_mise
    fi
}

function write_mise_stub() {
    cat > "${MISE_INSTALL_PATH}" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${MISE_CALLS_PATH}"
printf "GITHUB_TOKEN=%s\n" "${GITHUB_TOKEN:-}" >> "${MISE_CALLS_PATH}"
EOF

    chmod +x "${MISE_INSTALL_PATH}"
}

function write_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${GH_CALLS_PATH}"
printf "stub-token\n"
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

function write_failing_gh_stub() {
    cat > "${TEST_BIN_DIR}/gh" << 'EOF'
#!/usr/bin/env bash

printf "%s\n" "$*" >> "${GH_CALLS_PATH}"
exit 1
EOF

    chmod +x "${TEST_BIN_DIR}/gh"
}

@test "[common] mise" {
    compgen -G "${TMPL_SCRIPT_GLOB}" > /dev/null

    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    export PATH="${PATH}:${HOME}/.local/bin"
    [ -x "$(command -v mise)" ]
}

@test "[common] run_mise_install uses hardcoded min-release-age days" {
    printf "min-release-age=99\n" > "${HOME}/.npmrc"

    function mise() {
        echo "$*" > "${BATS_TEST_TMPDIR}/mise_install_args.txt"
    }

    run_mise_install

    run cat "${BATS_TEST_TMPDIR}/mise_install_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "install --before ${DEFAULT_NPM_MIN_RELEASE_AGE_DAYS}d" ]
}

@test "[common] run_after template installs pinned mise tools after apply" {
    write_mise_stub

    run bash "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install --before 7d\nGITHUB_TOKEN=' ]
}

@test "[common] run_after template skips when mise is not installed" {
    write_gh_stub

    run bash "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]
    [ ! -e "${MISE_CALLS_PATH}" ]
    [ ! -e "${GH_CALLS_PATH}" ]
}

@test "[common] run_after template reuses existing GITHUB_TOKEN" {
    write_mise_stub
    write_gh_stub
    export GITHUB_TOKEN="existing-token"

    run bash "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install --before 7d\nGITHUB_TOKEN=existing-token' ]
    [ ! -e "${GH_CALLS_PATH}" ]
}

@test "[common] run_after template exports gh token when GITHUB_TOKEN is unset" {
    write_mise_stub
    write_gh_stub

    run bash "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install --before 7d\nGITHUB_TOKEN=stub-token' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}

@test "[common] run_after template continues when gh token lookup fails" {
    write_mise_stub
    write_failing_gh_stub

    run bash "${RUN_AFTER_TEMPLATE}"
    [ "${status}" -eq 0 ]

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'install --before 7d\nGITHUB_TOKEN=' ]
    [ "$(< "${GH_CALLS_PATH}")" = "auth token" ]
}
