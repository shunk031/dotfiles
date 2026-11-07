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
    export FAKE_PANE="${BATS_TEST_TMPDIR}/pane.txt"
    export FAKE_NO_META="${BATS_TEST_TMPDIR}/no_meta"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH

    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
if [[ "$1" == --machine ]]; then
    [[ -e "${FAKE_REMOTE_DOWN}" ]] && { echo "boom: refused" >&2; exit 1; }
    shift 2
fi
case "$1 $2" in
"machine list") echo '[{"label":"remote","enabled":true}]' ;;
"agent list") cat "${FAKE_AGENTS}" ;;
"agent get") [[ ! -e "${FAKE_NO_META}" ]] ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"pane read") [[ -e "${FAKE_PANE}" ]] && cat "${FAKE_PANE}" ;;
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

function root_inbox() {
    jq -n --arg i "$1" '{result:{agents:[{name:"orch",pane_id:"p1",agent_status:"working",tokens:{inbox:$i}}]}}' > "${FAKE_AGENTS}"
}

@test "[common] herdr-meta-patrol ignores a leading inbox count change" {
    root_inbox "5 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    grep -q 'inbox=5 · 519' "${SENDER_CALLS}"

    rm "${SENDER_CALLS}"
    root_inbox "6 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol notifies when the inbox question text changes" {
    root_inbox "5 · 519 をマージするか"
    bash "${SCRIPT_PATH}"

    rm "${SENDER_CALLS}"
    root_inbox "5 · 520 をマージするか"
    bash "${SCRIPT_PATH}"
    grep -q 'inbox=5 · 520' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol normalizes only the leftover counts" {
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q '残り: 終わった・待機中の作業役 1 個' "${SENDER_CALLS}"

    rm "${SENDER_CALLS}"
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"idle"},{"name":"w2","pane_id":"p2","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]

    blocked_agent
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w1 p1' "${SENDER_CALLS}"
    rm "${SENDER_CALLS}"
    echo '{"result":{"agents":[{"name":"w2","pane_id":"p1","agent_status":"blocked"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w2 p1' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol detects first-time leftover input" {
    echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' > "${FAKE_PANE}"
    bash "${SCRIPT_PATH}"
    grep -q '\[local\] orch 入力欄: draft' "${SENDER_CALLS}"
    rm "${SENDER_CALLS}"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol retries after a failed delivery and keeps one pending log" {
    touch "${FAKE_NO_META}"
    blocked_agent
    bash "${SCRIPT_PATH}"
    bash "${SCRIPT_PATH}"
    [ "$(grep -c '自動巡回' "${HERDR_META_PATROL_STATE_DIR}/undelivered.log")" -eq 1 ]
    [ ! -s "${HERDR_META_PATROL_STATE_DIR}/keys.txt" ]

    rm "${FAKE_NO_META}"
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w1 p1' "${SENDER_CALLS}"
    [ ! -e "${HERDR_META_PATROL_STATE_DIR}/undelivered.log" ]
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

@test "[common] herdr-meta-patrol keeps counts single-line when pane list fails" {
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
case "$1 $2" in
"machine list") echo '[]' ;;
"agent list") echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"idle"}]}}' ;;
"agent get") exit 0 ;;
"pane list") echo '{"result":{"panes":[]}}'; exit 1 ;;
esac
STUB
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    run grep -q '中身が消えた' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
    run grep -v '^\[' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol logs connection errors to stderr only" {
    touch "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}" 2> "${BATS_TEST_TMPDIR}/stderr.txt"
    [ "$(grep -c '\[remote\] 接続できない（2 回とも失敗）' "${HERDR_META_PATROL_STATE_DIR}/latest.txt")" -eq 1 ]
    run grep -q 'boom' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
    run grep -q 'boom' "${SENDER_CALLS}"
    [ "${status}" -ne 0 ]
    [ "$(grep -c '\[remote\] agent list failed (exit 1): boom: refused' "${BATS_TEST_TMPDIR}/stderr.txt")" -eq 2 ]
}
