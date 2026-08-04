#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/skills.sh"
readonly MISE_HELPERS_PATH="./tests/install/common/mise_helpers.bash"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_04-install-skills.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
    source "${MISE_HELPERS_PATH}"
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

@test "[common] skills run-once template exists" {
    [ -f "${TMPL_SCRIPT_PATH}" ]
}

@test "[common] install_skills succeeds when the named npm runner is stale" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    SKILLS_CALLS_PATH="${BATS_TEST_TMPDIR}/skills_args.txt"
    export MISE_CALLS_PATH SKILLS_CALLS_PATH
    write_mise_with_stale_named_runner

    cat > "${BATS_TEST_TMPDIR}/bin/skills" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${SKILLS_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/skills"

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run install_skills
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/skills_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]
}

@test "[common] activate_mise evaluates mise activation output" {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export SKILLS_TEST_MISE_ACTIVATED=1'
fi
EOF
    chmod +x "${MISE_BIN}"

    activate_mise

    [ "${SKILLS_TEST_MISE_ACTIVATED}" = "1" ]
}

@test "[common] install_skills installs configured upstream skills globally" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_skills

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]
}

@test "[common] skills script runs full installation workflow" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"

    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export SKILLS_TEST_MISE_ACTIVATED=1'
    printf '%s\n' "export PATH=\"${HOME}/.local/bin:${PATH}\""
fi
if [ "$1" = "exec" ]; then
    [ "${2:-}" = "--" ] || exit 1
    shift 2
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"

    cat > "${BATS_TEST_TMPDIR}/bin/skills" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "${SKILLS_TEST_MISE_ACTIVATED:-unset}|$*" > "${SKILLS_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/skills"

    run env \
        DOTFILES_DEBUG=1 \
        HOME="${HOME}" \
        MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt" \
        SKILLS_CALLS_PATH="${BATS_TEST_TMPDIR}/skills_args.txt" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "activate bash" ]
    [ "${lines[1]}" = "exec -- skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/skills_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1|add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]
}
