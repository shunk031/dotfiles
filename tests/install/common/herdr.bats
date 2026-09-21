#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly MISE_HELPERS_PATH="./tests/install/common/mise_helpers.bash"

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
