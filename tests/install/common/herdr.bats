#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly MISE_HELPERS_PATH="./tests/install/common/mise_helpers.bash"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_03-install-herdr.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"
    OBSERVER_PID=''

    source "${SCRIPT_PATH}"
    source "${MISE_HELPERS_PATH}"
}

function teardown() {
    if [[ -n "${OBSERVER_PID}" ]] && kill -0 "${OBSERVER_PID}" 2> /dev/null; then
        kill "${OBSERVER_PID}" 2> /dev/null || true
        wait "${OBSERVER_PID}" 2> /dev/null || true
    fi
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

@test "[common] sync_herdr_skill succeeds when the named npm runner is stale" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_args.txt"
    export MISE_CALLS_PATH HERDR_CALLS_PATH
    write_mise_with_stale_named_runner

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${HERDR_CALLS_PATH}"
printf '%s\n' 'generated Herdr skill'
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run sync_herdr_skill
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- herdr --skill" ]

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--skill" ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "generated Herdr skill" ]
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
    [ "${lines[0]}" = "exec -- herdr integration install claude" ]
}

@test "[common] sync_herdr_skill writes the shared skill from Herdr" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = "exec -- herdr --skill" ]; then
    printf '%s\n' 'generated Herdr skill'
fi
EOF
    chmod +x "${MISE_BIN}"

    sync_herdr_skill

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- herdr --skill" ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "generated Herdr skill" ]
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
    [ "${2:-}" = "--" ] || exit 1
    shift 2
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${HERDR_CALLS_PATH}"
if [ "$*" = "--skill" ]; then
    printf '%s\n' "$*"
fi
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"

    run env \
        DOTFILES_DEBUG=1 \
        HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_args.txt" \
        HOME="${HOME}" \
        MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "activate bash" ]
    [ "${lines[1]}" = "install herdr" ]
    [ "${lines[2]}" = "exec -- herdr integration install claude" ]
    [ "${lines[3]}" = "exec -- herdr --skill" ]

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "integration install claude" ]
    [ "${lines[1]}" = "--skill" ]

    run cat "${HOME}/.agents/skills/herdr/SKILL.md"
    [ "${status}" -eq 0 ]
    [ "${output}" = "--skill" ]
}
