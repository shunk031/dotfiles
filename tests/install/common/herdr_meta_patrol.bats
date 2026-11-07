#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export HERDR_META_PATROL_STATE_DIR="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_SENDER="${BATS_TEST_TMPDIR}/sender"
    export HERDR_META_PATROL_RETRY_SLEEP=0
    export SENDER_CALLS="${BATS_TEST_TMPDIR}/sender_calls.txt"
    export FAKE_AGENTS="${BATS_TEST_TMPDIR}/agents.json"
    export FAKE_REMOTE_DOWN="${BATS_TEST_TMPDIR}/remote_down"
    export FAKE_NO_META="${BATS_TEST_TMPDIR}/no_meta"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
if [[ "$1" == --machine ]]; then
    [[ -e "${FAKE_REMOTE_DOWN}" ]] && exit 1
    shift 2
fi
case "$1 $2" in
"machine list") echo '[{"label":"remote","enabled":true}]' ;;
"agent list") cat "${FAKE_AGENTS}" ;;
"agent get") [[ ! -e "${FAKE_NO_META}" ]] ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"pane read") ;;
esac
STUB
    cat > "${HERDR_META_PATROL_SENDER}" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SENDER_CALLS}"
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr" "${HERDR_META_PATROL_SENDER}"
    echo '{"result":{"agents":[]}}' > "${FAKE_AGENTS}"
}

function blocked_agent() {
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"blocked"}]}}' > "${FAKE_AGENTS}"
}

@test "[common] herdr-meta-patrol stays silent when nothing is found" {
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol notifies meta once for a new line" {
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(wc -l < "${SENDER_CALLS}")" -ge 1 ]
    grep -q '^meta ' "${SENDER_CALLS}"
    grep -q '\[local\] blocked: w1 p1' "${SENDER_CALLS}"
    grep -q 'blocked: w1 p1' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"

    rm "${SENDER_CALLS}"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol notifies once per connection change" {
    touch "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}"
    grep -q '\[remote\] 接続できない' "${SENDER_CALLS}"

    rm "${SENDER_CALLS}"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]

    rm "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}"
    grep -q '\[remote\] 接続が回復した' "${SENDER_CALLS}"

    rm "${SENDER_CALLS}"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol logs undelivered messages when meta is missing" {
    touch "${FAKE_NO_META}"
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
    grep -q 'blocked: w1 p1' "${HERDR_META_PATROL_STATE_DIR}/undelivered.log"
}

@test "[common] herdr-meta-patrol repeats leftover input only after the interval" {
    mkdir -p "${HERDR_META_PATROL_STATE_DIR}"
    printf '%s\t%s\n' "$(date +%s)" '[local] orch 入力欄: draft' > "${HERDR_META_PATROL_STATE_DIR}/leftover.tsv"
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
case "$1 $2" in
"machine list") echo '[]' ;;
"agent list") echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle"}]}}' ;;
"agent get") exit 0 ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"pane read") printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' ;;
esac
STUB
    run bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]

    printf '%s\t%s\n' "$(($(date +%s) - 7200))" '[local] orch 入力欄: draft' > "${HERDR_META_PATROL_STATE_DIR}/leftover.tsv"
    run bash "${SCRIPT_PATH}"
    grep -q '入力欄: draft' "${SENDER_CALLS}"
}
