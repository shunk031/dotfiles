#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly MISE_HELPERS_PATH="./tests/install/common/mise_helpers.bash"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_03-install-herdr.sh.tmpl"
readonly OBSERVER_SCRIPT_PATH="./home/dot_config/exact_agents/skills/shunk031-orchestrate-herdr-workers/scripts/herdr-orchestrator-observer.sh"

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

@test "[common] observer coalesces scoped lifecycle truth and stops cleanly" {
    HERDR_OBSERVER_STUB_STATE="${BATS_TEST_TMPDIR}/observer-state"
    export HERDR_OBSERVER_STUB_STATE
    mkdir -p "${HERDR_OBSERVER_STUB_STATE}"
    mkdir -p "${BATS_TEST_TMPDIR}/observer-bin"
    cat > "${BATS_TEST_TMPDIR}/observer-bin/herdr" << 'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
state_dir="${HERDR_OBSERVER_STUB_STATE:?}"
command_name="${1:-} ${2:-}"
shift 2 || true
case "${command_name}" in
    "agent list")
        if [[ "$(<"${state_dir}/agents_mode")" == malformed ]]; then
            printf '%s\n' malformed-json
        else
            cat "${state_dir}/agents.json"
        fi
        ;;
    "agent read")
        target="${1:?}"
        [[ "${target}" != unreadable ]] || exit 1
        if [[ "${target}" == moving ]]; then
            printf 'moving %s\n' "$(date +%s%N)"
        else
            cat "${state_dir}/transcript_${target}"
        fi
        ;;
    "agent prompt")
        target="${1:?}"
        report="${2:?}"
        [[ "${target}" == orch264 ]] || exit 1
        one_line="${report//$'\n'/ }"
        printf '%s\n' "${one_line}" >> "${state_dir}/prompts"
        ;;
    "tab get")
        case "${1:?}" in
            w1:t1) printf '%s\n' '{"result":{"tab":{"label":"🚧 stale task"}}}' ;;
            w2:t1) printf '%s\n' '{"result":{"tab":{"label":"🚧 moving task"}}}' ;;
            w3:t1) printf '%s\n' '{"result":{"tab":{"label":"✅ clean audit"}}}' ;;
            w4:t1) printf '%s\n' '{"result":{"tab":{"label":"⛔ review and merge PR 264"}}}' ;;
            w5:t1) printf '%s\n' '{"result":{"tab":{"label":"🚧 unreadable task"}}}' ;;
            w6:t1) printf '%s\n' '{"result":{"tab":{"label":"🚧 foreign task"}}}' ;;
            *) exit 1 ;;
        esac
        ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "${BATS_TEST_TMPDIR}/observer-bin/herdr"
    cat > "${HERDR_OBSERVER_STUB_STATE}/agents.json" << 'EOF'
{"result":{"agents":[
  {"name":"stale","agent_status":"working","revision":1,"state_change_seq":1,"pane_id":"w1:p1","tab_id":"w1:t1"},
  {"name":"moving","agent_status":"working","revision":1,"state_change_seq":1,"pane_id":"w2:p1","tab_id":"w2:t1"},
  {"name":"complete","agent_status":"done","revision":1,"state_change_seq":1,"pane_id":"w3:p1","tab_id":"w3:t1"},
  {"name":"pr-wait","agent_status":"done","revision":1,"state_change_seq":1,"pane_id":"w4:p1","tab_id":"w4:t1"},
  {"name":"unreadable","agent_status":"working","revision":1,"state_change_seq":1,"pane_id":"w5:p1","tab_id":"w5:t1"},
  {"name":"foreign","agent_status":"working","revision":1,"state_change_seq":1,"pane_id":"w6:p1","tab_id":"w6:t1"}
]},"type":"agent_list"}
EOF
    printf '%s\n' 'stale transcript' > "${HERDR_OBSERVER_STUB_STATE}/transcript_stale"
    printf '%s\n' 'completed transcript' > "${HERDR_OBSERVER_STUB_STATE}/transcript_complete"
    printf '%s\n' 'open PR transcript' > "${HERDR_OBSERVER_STUB_STATE}/transcript_pr-wait"
    printf '%s\n' 'foreign transcript' > "${HERDR_OBSERVER_STUB_STATE}/transcript_foreign"
    printf '%s\n' malformed > "${HERDR_OBSERVER_STUB_STATE}/agents_mode"
    export HERDR_ENV=1
    PATH="${BATS_TEST_TMPDIR}/observer-bin:${PATH}"
    export PATH
    : > "${HERDR_OBSERVER_STUB_STATE}/prompts"

    launch_dir="${BATS_TEST_TMPDIR}/observer-launch"
    mkdir -p "${launch_dir}"
    launch_pid_file="${launch_dir}/pid"
    launch_log="${launch_dir}/observer.log"
    setsid bash -c '
        setsid "$1" --orchestrator orch264 --worker "stale|w1:p1|w1:t1" --worker "moving|w2:p1|w2:t1" --worker "complete|w3:p1|w3:t1" --worker "pr-wait|w4:p1|w4:t1" --worker "missing|w9:p1|w9:t1" --worker "unreadable|w5:p1|w5:t1" --interval-seconds 1 --stale-samples 2 >"$2" 2>&1 &
        printf "%s\n" "$!" >"$3"
        kill -TERM -- "-$$"
    ' bash "${OBSERVER_SCRIPT_PATH}" "${launch_log}" "${launch_pid_file}" || true
    OBSERVER_PID="$(<"${launch_pid_file}")"
    kill -0 "${OBSERVER_PID}"

    sleep 1.2
    [ ! -s "${HERDR_OBSERVER_STUB_STATE}/prompts" ]
    printf '%s\n' valid > "${HERDR_OBSERVER_STUB_STATE}/agents_mode"
    sleep 1.3

    [ "$(wc -l < "${HERDR_OBSERVER_STUB_STATE}/prompts")" -ge 1 ]
    grep -F 'OBSERVER orch264: bounded reconciliation required' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    grep -F 'worker=complete ' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    ! grep -Fq 'worker=moving ' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    sleep 1.3
    [ "$(wc -l < "${HERDR_OBSERVER_STUB_STATE}/prompts")" -eq 2 ]
    grep -F 'worker=stale ' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    ! grep -Fq 'worker=foreign ' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    ! grep -Fq 'pr-wait' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    ! grep -Fq 'unreadable' "${HERDR_OBSERVER_STUB_STATE}/prompts"
    printf '%s\n' 'stale transcript moved' > "${HERDR_OBSERVER_STUB_STATE}/transcript_stale"
    sleep 1.3
    [ "$(wc -l < "${HERDR_OBSERVER_STUB_STATE}/prompts")" -eq 2 ]
    sleep 1.3
    [ "$(wc -l < "${HERDR_OBSERVER_STUB_STATE}/prompts")" -eq 3 ]
    printf '%s\n' '{"result":{"agents":[]},"type":"agent_list"}' > "${HERDR_OBSERVER_STUB_STATE}/agents.json"
    sleep 1.3
    ! kill -0 "${OBSERVER_PID}"
    OBSERVER_PID=''
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

@test "[common] install_herdr_skill succeeds when the named npm runner is stale" {
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

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" run install_herdr_skill
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- skills add ogulcancelik/herdr --skill herdr --agent claude-code antigravity-cli --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/skills_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "add ogulcancelik/herdr --skill herdr --agent claude-code antigravity-cli --global --yes" ]
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

@test "[common] install_herdr_skill installs the shared skill globally" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_herdr_skill

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "exec -- skills add ogulcancelik/herdr --skill herdr --agent claude-code antigravity-cli --global --yes" ]
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
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"

    cat > "${BATS_TEST_TMPDIR}/bin/skills" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "${HERDR_TEST_MISE_ACTIVATED:-unset}|$*" > "${SKILLS_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/skills"

    run env \
        DOTFILES_DEBUG=1 \
        HERDR_CALLS_PATH="${BATS_TEST_TMPDIR}/herdr_args.txt" \
        HOME="${HOME}" \
        MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt" \
        SKILLS_CALLS_PATH="${BATS_TEST_TMPDIR}/skills_args.txt" \
        PATH="${BATS_TEST_TMPDIR}/bin:${PATH}" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "activate bash" ]
    [ "${lines[1]}" = "install herdr" ]
    [ "${lines[2]}" = "exec -- herdr integration install claude" ]
    [ "${lines[3]}" = "exec -- skills add ogulcancelik/herdr --skill herdr --agent claude-code antigravity-cli --global --yes" ]

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "integration install claude" ]

    run cat "${BATS_TEST_TMPDIR}/skills_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1|add ogulcancelik/herdr --skill herdr --agent claude-code antigravity-cli --global --yes" ]
}
