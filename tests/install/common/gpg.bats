#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/gpg.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_98-warmup-gpg-signing-cache.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export TEST_BIN_DIR="${BATS_TEST_TMPDIR}/bin"
    export GIT_CONFIG_PATH="${BATS_TEST_TMPDIR}/git_config.txt"
    export GPG_CALLS_PATH="${BATS_TEST_TMPDIR}/gpg_calls.txt"
    export GPGCONF_CALLS_PATH="${BATS_TEST_TMPDIR}/gpgconf_calls.txt"
    PATH="${TEST_BIN_DIR}:$(getconf PATH)"
    export PATH

    mkdir -p "${HOME}" "${TEST_BIN_DIR}"
    rm -f "${GIT_CONFIG_PATH}" "${GPG_CALLS_PATH}" "${GPGCONF_CALLS_PATH}"
    unset CI

    source "${SCRIPT_PATH}"
}

function write_git_stub() {
    cat > "${TEST_BIN_DIR}/git" << 'EOF'
#!/usr/bin/env bash

if [ "$1" = "config" ] && [ "$2" = "--get" ] && [ "$3" = "--bool" ] && [ "$4" = "commit.gpgsign" ]; then
    sed -n 's/^commit.gpgsign=//p' "${GIT_CONFIG_PATH}"
    exit 0
fi

if [ "$1" = "config" ] && [ "$2" = "--get" ] && [ "$3" = "user.signingkey" ]; then
    sed -n 's/^user.signingkey=//p' "${GIT_CONFIG_PATH}"
    exit 0
fi

exit 1
EOF

    chmod +x "${TEST_BIN_DIR}/git"
}

function write_gpg_stub() {
    cat > "${TEST_BIN_DIR}/gpg" << 'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "${GPG_CALLS_PATH}"
cat > /dev/null
EOF

    chmod +x "${TEST_BIN_DIR}/gpg"
}

function write_failing_gpg_stub() {
    cat > "${TEST_BIN_DIR}/gpg" << 'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "${GPG_CALLS_PATH}"
cat > /dev/null
exit 1
EOF

    chmod +x "${TEST_BIN_DIR}/gpg"
}

function write_gpgconf_stub() {
    cat > "${TEST_BIN_DIR}/gpgconf" << 'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "${GPGCONF_CALLS_PATH}"
EOF

    chmod +x "${TEST_BIN_DIR}/gpgconf"
}

@test "[common] gpg warm-up run-once template exists" {
    [ -f "${TMPL_SCRIPT_PATH}" ]
}

@test "[common] gpg warm-up template documents install ordering" {
    grep -F "run_once_after_99-install-gh-extensions.sh.tmpl" "${TMPL_SCRIPT_PATH}"
    grep -F "run_after_99-refresh-chezmoi-notify-cache.sh.tmpl" "${TMPL_SCRIPT_PATH}"
    grep -F "gpg-agent.conf" "${TMPL_SCRIPT_PATH}"
    grep -F "private keys" "${TMPL_SCRIPT_PATH}"
    grep -F "git config" "${TMPL_SCRIPT_PATH}"
}

@test "[common] gpg warm-up skips when commit signing is disabled" {
    write_git_stub
    write_gpg_stub
    printf '%s\n' "commit.gpgsign=false" > "${GIT_CONFIG_PATH}"

    function is_interactive_tty() {
        return 0
    }

    run main
    [ "${status}" -eq 0 ]
    [ ! -e "${GPG_CALLS_PATH}" ]
}

@test "[common] gpg warm-up uses configured signing key" {
    write_git_stub
    write_gpg_stub
    write_gpgconf_stub
    {
        printf '%s\n' "commit.gpgsign=true"
        printf '%s\n' "user.signingkey=D55D775A7951407C"
    } > "${GIT_CONFIG_PATH}"

    function is_interactive_tty() {
        return 0
    }

    run main
    [ "${status}" -eq 0 ]

    run cat "${GPG_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--local-user D55D775A7951407C --clearsign" ]

    run cat "${GPGCONF_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--reload gpg-agent" ]
}

@test "[common] gpg warm-up signs without local user when signing key is unset" {
    write_git_stub
    write_gpg_stub
    printf '%s\n' "commit.gpgsign=true" > "${GIT_CONFIG_PATH}"

    function is_interactive_tty() {
        return 0
    }

    run main
    [ "${status}" -eq 0 ]

    run cat "${GPG_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--clearsign" ]
}

@test "[common] gpg warm-up continues when signing fails" {
    write_git_stub
    write_failing_gpg_stub
    printf '%s\n' "commit.gpgsign=true" > "${GIT_CONFIG_PATH}"

    function is_interactive_tty() {
        return 0
    }

    run main
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Warning: Failed to warm up GPG signing cache. Continuing install."* ]]
}

@test "[common] gpg warm-up skips in CI" {
    write_git_stub
    write_gpg_stub
    export CI=true

    function is_interactive_tty() {
        return 0
    }

    run main
    [ "${status}" -eq 0 ]
    [ ! -e "${GPG_CALLS_PATH}" ]
}
