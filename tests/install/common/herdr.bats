#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_03-install-herdr.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
}

function teardown() {
    PATH=$(getconf PATH)
    export PATH
}

function write_mise_logger() {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
EOF
    chmod +x "${MISE_BIN}"
}

@test "[common] herdr run-once template exists" {
    [ -f "${TMPL_SCRIPT_PATH}" ]
}

@test "[common] activate_mise evaluates mise activation output" {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export HERDR_TEST_MISE_ACTIVATED=1'
fi
EOF
    chmod +x "${MISE_BIN}"

    activate_mise

    [ "${HERDR_TEST_MISE_ACTIVATED}" = "1" ]
}

@test "[common] install_herdr installs herdr with mise" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_herdr

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "install herdr" ]
}

@test "[common] install_herdr_integrations installs configured integrations" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_herdr_integrations

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "exec herdr -- herdr integration install claude" ]
    [ "${lines[1]}" = "exec herdr -- herdr integration install codex" ]
}

@test "[common] install_herdr_skill installs the shared skill globally" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_herdr_skill

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec node -- npx -y skills add ogulcancelik/herdr --skill herdr --agent claude-code codex antigravity-cli --global --yes" ]
}

@test "[common] herdr script runs full installation workflow" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"

    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export HERDR_TEST_MISE_ACTIVATED=1'
    printf '%s\n' "export PATH=\"${HOME}/.local/bin:${PATH}\""
fi
if [ "$1" = "exec" ]; then
    shift
    while [ "$1" != "--" ]; do
        shift
    done
    shift
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${HERDR_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"

    cat > "${BATS_TEST_TMPDIR}/bin/npx" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "${HERDR_TEST_MISE_ACTIVATED:-unset}|$*" > "${NPX_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/npx"

    run env \
        DOTFILES_DEBUG=1 \
        HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_args.txt" \
        HOME="${HOME}" \
        MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt" \
        NPX_CALLS_PATH="${BATS_TEST_TMPDIR}/npx_args.txt" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "activate bash" ]
    [ "${lines[1]}" = "install herdr" ]
    [ "${lines[2]}" = "exec herdr -- herdr integration install claude" ]
    [ "${lines[3]}" = "exec herdr -- herdr integration install codex" ]
    [ "${lines[4]}" = "exec node -- npx -y skills add ogulcancelik/herdr --skill herdr --agent claude-code codex antigravity-cli --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "integration install claude" ]
    [ "${lines[1]}" = "integration install codex" ]

    run cat "${BATS_TEST_TMPDIR}/npx_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1|-y skills add ogulcancelik/herdr --skill herdr --agent claude-code codex antigravity-cli --global --yes" ]
}
