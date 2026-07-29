#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/skills.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_04-install-skills.sh.tmpl"

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

@test "[common] skills run-once template exists" {
    [ -f "${TMPL_SCRIPT_PATH}" ]
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
    [ "${output}" = "exec npm:skills -- skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]
}

@test "[common] install_skills skips when mise is unavailable" {
    install_skills

    [ ! -e "${BATS_TEST_TMPDIR}/mise_args.txt" ]
}

@test "[common] install_skills keeps an existing local skill" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger
    mkdir -p "${HOME}/.claude/skills/skill-creator"

    install_skills

    [ ! -e "${BATS_TEST_TMPDIR}/mise_args.txt" ]
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
    shift
    while [ "$1" != "--" ]; do
        shift
    done
    shift
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
    [ "${lines[1]}" = "exec npm:skills -- skills add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/skills_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1|add anthropics/skills --skill skill-creator --agent claude-code --global --yes" ]
}
