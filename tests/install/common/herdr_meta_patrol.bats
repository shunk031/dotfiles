#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol"
readonly SHARED_INPUT_STATE_PARSER="${HOME}/.agents/skills/shunk031-herdr-orchestrate-workers/scripts/herdr-visible-input-state.awk"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export XDG_STATE_HOME="${BATS_TEST_TMPDIR}/xdg-state"
    export HERDR_META_PATROL_STATE_DIR="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_SENDER="${BATS_TEST_TMPDIR}/sender"
    export HERDR_META_PATROL_RETRY_SLEEP=0
    export SENDER_CALLS="${BATS_TEST_TMPDIR}/sender_calls.txt"
    export FAKE_AGENTS="${BATS_TEST_TMPDIR}/agents.json"
    export FAKE_MACHINE_LIST_DOWN="${BATS_TEST_TMPDIR}/machine_list_down"
    export FAKE_REMOTE_DOWN="${BATS_TEST_TMPDIR}/remote_down"
    export FAKE_PANE="${BATS_TEST_TMPDIR}/pane.txt"
    export FAKE_INPUT_STATE=empty
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
"machine list")
    [[ ! -e "${FAKE_MACHINE_LIST_DOWN}" ]] || exit 1
    echo "${FAKE_MACHINE_LIST:-[]}"
    ;;
"agent list") cat "${FAKE_AGENTS}" ;;
"agent get") [[ ! -e "${FAKE_NO_META}" ]] ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"pane read")
    [[ -z "${FAKE_PANE_READS:-}" ]] || touch "${FAKE_PANE_READS}"
    [[ -e "${FAKE_PANE}" ]] && cat "${FAKE_PANE}"
    ;;
esac
STUB
    cat > "${HERDR_META_PATROL_SENDER}" << 'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SENDER_CALLS}"
STUB
    if [[ -r "${SHARED_INPUT_STATE_PARSER}" ]]; then
        ln -s "${SHARED_INPUT_STATE_PARSER}" "${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk"
    else
        cat > "${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk" << 'STUB'
END { print ENVIRON["FAKE_INPUT_STATE"] }
STUB
    fi
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr" "${HERDR_META_PATROL_SENDER}"
    echo '{"result":{"agents":[]}}' > "${FAKE_AGENTS}"
}

function register_root() {
    mkdir -p "${XDG_STATE_HOME}/meta"
    printf '%s\t%s\n' "$1" "$2" >> "${XDG_STATE_HOME}/meta/roots.tsv"
}

function blocked_agent() {
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"blocked"}]}}' > "${FAKE_AGENTS}"
}

@test "[common] herdr-meta-patrol stays silent when nothing is found" {
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol still scans local when machine listing fails" {
    touch "${FAKE_MACHINE_LIST_DOWN}"
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] blocked: w1 p1' "${SENDER_CALLS}"
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
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
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

function inbox_agent() {
    jq -n --arg inbox "$1" --arg relay "$2" --arg url "$3" --arg status "${4:-working}" '{result:{agents:[{name:"new-root",pane_id:"p1",agent_status:$status,tokens:{inbox:$inbox,relay:$relay,url:$url}}]}}' > "${FAKE_AGENTS}"
}

@test "[common] herdr-meta-patrol reports full relay values and URL presence for registered roots" {
    register_root Local new-root
    inbox_agent "5 · review task" "/agent/files/result.md" "https://example.test/result.md"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] new-root inbox=5 · review task relay=/agent/files/result.md url=present' "${SENDER_CALLS}"
    ! grep -Fq 'https://example.test/result.md' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol reports an unregistered inbox agent once despite token changes" {
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    inbox_agent "5 · first text" "/agent/files/result.md" "https://example.test/result.md" idle
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] unregistered agent with inbox token: new-root' "${SENDER_CALLS}"
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    ! grep -Fq 'first text' "${SENDER_CALLS}"
    ! grep -Fq '/agent/files/result.md' "${SENDER_CALLS}"
    ! grep -Fq 'https://example.test/result.md' "${SENDER_CALLS}"
    [ ! -e "${FAKE_PANE_READS}" ]
    [ ! -e "${XDG_STATE_HOME}/meta/roots.tsv" ]

    rm "${SENDER_CALLS}"
    inbox_agent "6 · changed text" "/agent/files/other.md" "https://example.test/other.md" idle
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol ignores comment-only root registries" {
    mkdir -p "${XDG_STATE_HOME}/meta"
    printf '# roots are maintained by meta\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    inbox_agent 0 "/agent/files/result.md" "https://example.test/result.md"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] unregistered agent with inbox token: new-root' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol uses the saved remote machine alias for roots" {
    register_root remote orch
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    root_inbox "5 · review task"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[remote] orch inbox=5 · review task' "${SENDER_CALLS}"
    grep -Fq '[local] unregistered agent with inbox token: orch' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol ignores a leading inbox count change" {
    register_root Local orch
    root_inbox "5 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    grep -q 'inbox=5 · 519' "${SENDER_CALLS}"

    rm "${SENDER_CALLS}"
    root_inbox "6 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol notifies when the inbox question text changes" {
    register_root Local orch
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
    register_root Local new-root
    echo '{"result":{"agents":[{"name":"new-root","pane_id":"p0","agent_status":"idle","tokens":{"inbox":"0"}},{"name":"w1","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ ! -e "${SENDER_CALLS}" ]

    blocked_agent
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w1 p1' "${SENDER_CALLS}"
    rm "${SENDER_CALLS}"
    echo '{"result":{"agents":[{"name":"w2","pane_id":"p1","agent_status":"blocked"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w2 p1' "${SENDER_CALLS}"
}

@test "[common] herdr-meta-patrol counts token-less orch as non-root without reading its input" {
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' > "${FAKE_PANE}"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ ! -e "${FAKE_PANE_READS}" ]
    run grep -q '入力欄:' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol ignores the recipient's blocked, inbox, and input state" {
    register_root Local meta
    export FAKE_INPUT_STATE=occupied
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    echo '{"result":{"agents":[{"name":"meta","pane_id":"p1","agent_status":"blocked","tokens":{"inbox":"5 · pending","relay":"/agent/files/meta.md","url":"https://example.test/meta"}}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' > "${FAKE_PANE}"

    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${SENDER_CALLS}" ]
    [ ! -e "${FAKE_PANE_READS}" ]
    run grep -q . "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol reads a registered inbox-zero root without counting or notifying its inbox" {
    register_root Local orch
    export FAKE_INPUT_STATE=occupied
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle","tokens":{"inbox":"0"}}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' > "${FAKE_PANE}"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -e "${FAKE_PANE_READS}" ]
    grep -Fq '[local] orch 入力欄: occupied' "${SENDER_CALLS}"
    run grep -q 'inbox=' "${SENDER_CALLS}"
    [ "${status}" -ne 0 ]
    run grep -q 'inbox=' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
    run grep -q '残り: 終わった・待機中の作業役' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol detects first-time leftover input" {
    register_root Local orch
    export FAKE_INPUT_STATE=occupied
    echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle","tokens":{"inbox":"0"}}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' > "${FAKE_PANE}"
    bash "${SCRIPT_PATH}"
    grep -q '\[local\] orch 入力欄: occupied' "${SENDER_CALLS}"
    rm "${SENDER_CALLS}"
    bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]
}

@test "[common] herdr-meta-patrol ignores plugin panel text above an empty root input line" {
    [[ -r "${SHARED_INPUT_STATE_PARSER}" ]] || skip "guarded sender input-state detector is not installed"
    register_root Local orch
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    cp ./tests/fixtures/herdr-meta-patrol/agent-panel-empty-input.ansi "${FAKE_PANE}"
    echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"

    state="$(LC_ALL=C awk -f "${SHARED_INPUT_STATE_PARSER}" < "${FAKE_PANE}")"
    [ "${state}" = empty ]
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -e "${FAKE_PANE_READS}" ]
    [ -L "${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk" ]
    run grep -q '入力欄:' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
    run grep -q '残り: 終わった・待機中の作業役' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
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
    register_root Local orch
    export FAKE_INPUT_STATE=occupied
    mkdir -p "${HERDR_META_PATROL_STATE_DIR}"
    printf '%s\t%s\n' "$(date +%s)" '[local] orch 入力欄: occupied' > "${HERDR_META_PATROL_STATE_DIR}/leftover.tsv"
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
case "$1 $2" in
"machine list") echo '[]' ;;
"agent list") echo '{"result":{"agents":[{"name":"orch","pane_id":"p1","agent_status":"idle","tokens":{"inbox":"0"}}]}}' ;;
"agent get") exit 0 ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"pane read") printf '%s\n' '────────────────────────────' '❯ draft' '────────────────────────────' ;;
esac
STUB
    run bash "${SCRIPT_PATH}"
    [ ! -e "${SENDER_CALLS}" ]

    printf '%s\t%s\n' "$(($(date +%s) - 7200))" '[local] orch 入力欄: occupied' > "${HERDR_META_PATROL_STATE_DIR}/leftover.tsv"
    run bash "${SCRIPT_PATH}"
    grep -q '入力欄: occupied' "${SENDER_CALLS}"
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
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    touch "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}" 2> "${BATS_TEST_TMPDIR}/stderr.txt"
    [ "$(grep -c '\[remote\] 接続できない（2 回とも失敗）' "${HERDR_META_PATROL_STATE_DIR}/latest.txt")" -eq 1 ]
    run grep -q 'boom' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
    run grep -q 'boom' "${SENDER_CALLS}"
    [ "${status}" -ne 0 ]
    [ "$(grep -c '\[remote\] agent list failed (exit 1)' "${BATS_TEST_TMPDIR}/stderr.txt")" -eq 2 ]
    run grep -q 'boom' "${BATS_TEST_TMPDIR}/stderr.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol scans machines concurrently" {
    export LOCAL_STARTED="${BATS_TEST_TMPDIR}/local_started"
    export LOCAL_DONE="${BATS_TEST_TMPDIR}/local_done"
    export REMOTE_DURING_LOCAL="${BATS_TEST_TMPDIR}/remote_during_local"
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
machine=local
if [[ "$1" == --machine ]]; then
    machine="$2"
    shift 2
fi
case "$1 $2" in
"machine list") echo '[{"label":"remote","enabled":true}]' ;;
"agent list")
    if [[ "${machine}" == local ]]; then
        touch "${LOCAL_STARTED}"
        sleep 2
        touch "${LOCAL_DONE}"
    else
        for _ in {1..400}; do
            [[ -e "${LOCAL_STARTED}" ]] && break
            sleep 0.01
        done
        [[ -e "${LOCAL_STARTED}" ]] || exit 1
        if [[ ! -e "${LOCAL_DONE}" ]]; then touch "${REMOTE_DURING_LOCAL}"; fi
    fi
    echo '{"result":{"agents":[]}}'
    ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"agent get") exit 0 ;;
esac
STUB
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -e "${REMOTE_DURING_LOCAL}" ]
}
