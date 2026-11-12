#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol"
readonly QUEUE_PATH="${PWD}/home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol-queue"
readonly SHARED_INPUT_STATE_PARSER="${HOME}/.agents/skills/shunk031-herdr-orchestrate-workers/scripts/herdr-visible-input-state.awk"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export XDG_STATE_HOME="${BATS_TEST_TMPDIR}/xdg-state"
    export HERDR_META_PATROL_STATE_DIR="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_QUEUE="${QUEUE_PATH}"
    export HERDR_META_PATROL_INPUT_PARSER="${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk"
    export HERDR_META_PATROL_RETRY_SLEEP=0
    export FAKE_AGENTS="${BATS_TEST_TMPDIR}/agents.json"
    export FAKE_MACHINE_LIST_DOWN="${BATS_TEST_TMPDIR}/machine_list_down"
    export FAKE_REMOTE_DOWN="${BATS_TEST_TMPDIR}/remote_down"
    export FAKE_PANE="${BATS_TEST_TMPDIR}/pane.txt"
    export FAKE_RECENT_PANE="${BATS_TEST_TMPDIR}/recent.txt"
    export HERDR_META_PATROL_FINDINGS_DIR="${BATS_TEST_TMPDIR}/findings.d"
    export FAKE_INPUT_STATE=empty
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
"agent get") exit 0 ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"tab list") if [[ -n "${FAKE_TABS:-}" ]]; then echo "${FAKE_TABS}"; else echo '{"result":{"tabs":[]}}'; fi ;;
"pane read")
    if [[ " $* " == *" --source recent "* ]]; then
        [[ -e "${FAKE_RECENT_PANE}" ]] && cat "${FAKE_RECENT_PANE}"
        exit 0
    fi
    [[ -z "${FAKE_PANE_READS:-}" ]] || touch "${FAKE_PANE_READS}"
    [[ -e "${FAKE_PANE}" ]] && cat "${FAKE_PANE}"
    ;;
esac
STUB
    if [[ -r "${SHARED_INPUT_STATE_PARSER}" ]]; then
        ln -s "${SHARED_INPUT_STATE_PARSER}" "${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk"
    else
        cat > "${BATS_TEST_TMPDIR}/herdr-visible-input-state.awk" << 'STUB'
END { print ENVIRON["FAKE_INPUT_STATE"] }
STUB
    fi
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"
    echo '{"result":{"agents":[]}}' > "${FAKE_AGENTS}"
}

# @description Print the text of every unread queued message.
function calls() {
    bash "${QUEUE_PATH}" read | jq -r '.text'
}

# @description Acknowledge every queued message.
function ack_all() {
    bash "${QUEUE_PATH}" ack "$(cat "${HERDR_META_PATROL_STATE_DIR}/queue.seq" 2> /dev/null || echo 0)"
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
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol still scans local when machine listing fails" {
    touch "${FAKE_MACHINE_LIST_DOWN}"
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] blocked: w1 p1' <(calls)
}

@test "[common] herdr-meta-patrol notifies meta once for a new line" {
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(calls | wc -l)" -ge 1 ]
    grep -q '\[local\] blocked: w1 p1' <(calls)
    grep -q 'blocked: w1 p1' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"

    ack_all
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol notifies once per connection change" {
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    touch "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}"
    grep -q '\[remote\] 接続できない' <(calls)

    ack_all
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]

    rm "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}"
    grep -q '\[remote\] 接続が回復した' <(calls)

    ack_all
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
}

# @description Make queue appends fail while the other queue subcommands still work.
function fail_queue_adds() {
    cat > "${BATS_TEST_TMPDIR}/failing-queue" << STUB
#!/usr/bin/env bash
[[ "\$1" != add ]] || exit 1
exec bash "${QUEUE_PATH}" "\$@"
STUB
    chmod +x "${BATS_TEST_TMPDIR}/failing-queue"
    export HERDR_META_PATROL_QUEUE="${BATS_TEST_TMPDIR}/failing-queue"
}

@test "[common] herdr-meta-patrol queues findings without typing into any pane" {
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
case "$1 $2" in
"machine list") echo '[]' ;;
"agent list") echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"blocked"}]}}' ;;
"pane list") echo '{"result":{"panes":[]}}' ;;
"agent prompt" | "pane send-text" | "pane send-keys" | "agent send-keys") touch "${BATS_TEST_TMPDIR}/typed"; exit 1 ;;
esac
STUB
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -e "${BATS_TEST_TMPDIR}/typed" ]
    [ "$(bash "${QUEUE_PATH}" read | jq -r '.kind')" = findings ]
    grep -Fq '[local] blocked: w1 p1' <(calls)
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
    grep -Fq '[local] new-root inbox=5 · review task relay=/agent/files/result.md url=present' <(calls)
    ! grep -Fq 'https://example.test/result.md' <(calls)
}

@test "[common] herdr-meta-patrol reports an unregistered inbox agent once despite token changes" {
    export FAKE_PANE_READS="${BATS_TEST_TMPDIR}/pane_reads"
    inbox_agent "5 · first text" "/agent/files/result.md" "https://example.test/result.md" idle
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] unregistered agent with inbox token: new-root' <(calls)
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    ! grep -Fq 'first text' <(calls)
    ! grep -Fq '/agent/files/result.md' <(calls)
    ! grep -Fq 'https://example.test/result.md' <(calls)
    [ ! -e "${FAKE_PANE_READS}" ]
    [ ! -e "${XDG_STATE_HOME}/meta/roots.tsv" ]

    ack_all
    inbox_agent "6 · changed text" "/agent/files/other.md" "https://example.test/other.md" idle
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol ignores comment-only root registries" {
    mkdir -p "${XDG_STATE_HOME}/meta"
    printf '# roots are maintained by meta\n' > "${XDG_STATE_HOME}/meta/roots.tsv"
    inbox_agent 0 "/agent/files/result.md" "https://example.test/result.md"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] unregistered agent with inbox token: new-root' <(calls)
}

@test "[common] herdr-meta-patrol uses the saved remote machine alias for roots" {
    register_root remote orch
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    root_inbox "5 · review task"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[remote] orch inbox=5 · review task' <(calls)
    grep -Fq '[local] unregistered agent with inbox token: orch' <(calls)
}

@test "[common] herdr-meta-patrol ignores a leading inbox count change" {
    register_root Local orch
    root_inbox "5 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    grep -q 'inbox=5 · 519' <(calls)

    ack_all
    root_inbox "6 · 519 をマージするか"
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol notifies when the inbox question text changes" {
    register_root Local orch
    root_inbox "5 · 519 をマージするか"
    bash "${SCRIPT_PATH}"

    ack_all
    root_inbox "5 · 520 をマージするか"
    bash "${SCRIPT_PATH}"
    grep -q 'inbox=5 · 520' <(calls)
}

@test "[common] herdr-meta-patrol normalizes only the leftover counts" {
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q '残り: 終わった・待機中の作業役 1 個' <(calls)

    ack_all
    echo '{"result":{"agents":[{"name":"w1","pane_id":"p1","agent_status":"idle"},{"name":"w2","pane_id":"p2","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
    register_root Local new-root
    echo '{"result":{"agents":[{"name":"new-root","pane_id":"p0","agent_status":"idle","tokens":{"inbox":"0"}},{"name":"w1","pane_id":"p1","agent_status":"idle"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q '残り: 終わった・待機中の作業役 1 個' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ -z "$(calls)" ]

    blocked_agent
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w1 p1' <(calls)
    ack_all
    echo '{"result":{"agents":[{"name":"w2","pane_id":"p1","agent_status":"blocked"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"
    grep -q 'blocked: w2 p1' <(calls)
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
    [ -z "$(calls)" ]
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
    grep -Fq '[local] orch 入力欄: occupied' <(calls)
    run grep -q 'inbox=' <(calls)
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
    grep -q '\[local\] orch 入力欄: occupied' <(calls)
    ack_all
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
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

@test "[common] herdr-meta-patrol keeps its state when a queue append fails and retries" {
    fail_queue_adds
    blocked_agent
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ ! -s "${HERDR_META_PATROL_STATE_DIR}/keys.txt" ]
    [ -z "$(calls)" ]

    export HERDR_META_PATROL_QUEUE="${QUEUE_PATH}"
    bash "${SCRIPT_PATH}"
    [ "$(grep -c 'blocked: w1 p1' <(calls))" -eq 1 ]
    grep -q 'blocked: w1 p1' "${HERDR_META_PATROL_STATE_DIR}/keys.txt"
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
    [ -z "$(calls)" ]

    printf '%s\t%s\n' "$(($(date +%s) - 7200))" '[local] orch 入力欄: occupied' > "${HERDR_META_PATROL_STATE_DIR}/leftover.tsv"
    run bash "${SCRIPT_PATH}"
    grep -q '入力欄: occupied' <(calls)
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
    run grep -q 'boom' <(calls)
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

function digest_roots() {
    jq -n --arg s1 "$1" --arg i1 "$2" --arg s2 "$3" '{result:{agents:[
        {name:"orch",pane_id:"p1",tab_id:"t1",agent_status:$s1,tokens:{inbox:$i1}},
        {name:"orch2",pane_id:"p2",tab_id:"t2",agent_status:$s2,tokens:{inbox:"0"}}]}}' > "${FAKE_AGENTS}"
}

@test "[common] herdr-meta-patrol digest records a silent baseline and stays silent without changes" {
    export HERDR_META_PATROL_DIGEST_SECONDS=0
    export FAKE_TABS='{"result":{"tabs":[{"tab_id":"t1","label":"🤖 Orchestrator"},{"tab_id":"t2","label":"🤖 Orch2"}]}}'
    register_root Local orch
    register_root Local orch2
    digest_roots working 0 working
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]
    grep -Fq "$(printf 'local\torch\tworking\t🤖 Orchestrator\t0')" "${HERDR_META_PATROL_STATE_DIR}/digest.tsv"

    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol digest sends one line per changed root only" {
    export HERDR_META_PATROL_DIGEST_SECONDS=0
    export FAKE_TABS='{"result":{"tabs":[{"tab_id":"t1","label":"🤖 Orchestrator"},{"tab_id":"t2","label":"🤖 Orch2"}]}}'
    register_root Local orch
    register_root Local orch2
    digest_roots working 0 working
    bash "${SCRIPT_PATH}"

    digest_roots done 0 working
    export FAKE_TABS='{"result":{"tabs":[{"tab_id":"t1","label":"✅ Orchestrator"},{"tab_id":"t2","label":"🤖 Orch2"}]}}'
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(grep -c '進捗まとめ（自動巡回）' <(calls))" -eq 1 ]
    grep -Fq '[local] orch: 状態 working → done / タブ 🤖 Orchestrator → ✅ Orchestrator' <(calls)
    run grep -Fq 'orch2' <(calls)
    [ "${status}" -ne 0 ]
    run grep -Fq '自動巡回（herdr-meta-patrol）' <(calls)
    [ "${status}" -ne 0 ]

    ack_all
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]
}

@test "[common] herdr-meta-patrol digest waits for its interval" {
    register_root Local orch
    register_root Local orch2
    digest_roots working 0 working
    bash "${SCRIPT_PATH}"

    digest_roots done 0 working
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ -z "$(calls)" ]

    printf '%s\n' "$(($(date +%s) - 1800))" > "${HERDR_META_PATROL_STATE_DIR}/digest.epoch"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] orch: 状態 working → done' <(calls)
}

@test "[common] herdr-meta-patrol digest reports a missing root and keeps an unreadable machine's state" {
    export HERDR_META_PATROL_DIGEST_SECONDS=0
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    register_root Local orch
    register_root remote rorch
    jq -n '{result:{agents:[{name:"orch",pane_id:"p1",agent_status:"working"},{name:"rorch",pane_id:"p2",agent_status:"working"}]}}' > "${FAKE_AGENTS}"
    bash "${SCRIPT_PATH}"

    touch "${FAKE_REMOTE_DOWN}"
    echo '{"result":{"agents":[]}}' > "${FAKE_AGENTS}"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] orch: 状態 working → 不在' <(calls)
    run grep -Fq '[remote] rorch:' <(calls)
    [ "${status}" -ne 0 ]
    grep -Fq "$(printf 'remote\trorch\tworking')" "${HERDR_META_PATROL_STATE_DIR}/digest.tsv"
}

@test "[common] herdr-meta-patrol retries a digest that could not be queued" {
    register_root Local orch
    root_inbox "first question"
    bash "${SCRIPT_PATH}"

    ack_all
    fail_queue_adds
    root_inbox "second question"
    printf '%s\n' 1 > "${HERDR_META_PATROL_STATE_DIR}/digest.epoch"
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
    grep -Fq 'first question' "${HERDR_META_PATROL_STATE_DIR}/digest.tsv"
    [ "$(cat "${HERDR_META_PATROL_STATE_DIR}/digest.epoch")" = 1 ]

    export HERDR_META_PATROL_QUEUE="${QUEUE_PATH}"
    bash "${SCRIPT_PATH}"
    grep -Fq '[local] orch: inbox first question → second question' <(calls)
    [ "$(bash "${QUEUE_PATH}" read | jq -r 'select(.kind == "digest") | .seq' | wc -l)" -eq 1 ]
    grep -Fq 'second question' "${HERDR_META_PATROL_STATE_DIR}/digest.tsv"
    [ "$(cat "${HERDR_META_PATROL_STATE_DIR}/digest.epoch")" -gt 1 ]
}

function stopped_worker() {
    jq -n --arg s "$1" '{result:{agents:[{name:"w1",pane_id:"p1",agent_status:$s}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' "$2" '' '› ' > "${FAKE_RECENT_PANE}"
}

@test "[common] herdr-meta-patrol reports an agent stopped by a 429 once until it changes" {
    stopped_worker idle '■ exceeded retry limit, last status: 429 Too Many Requests'
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] w1: 429 で停止' <(calls)
    run grep -Fq '（Gateway 予算）' <(calls)
    [ "${status}" -ne 0 ]

    ack_all
    run bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]

    stopped_worker idle 'All checks passed.'
    run bash "${SCRIPT_PATH}"
    run grep -Fq '429 で停止' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]

    ack_all
    stopped_worker done '  ⎿  API Error: 429 Too many requests, please wait before trying again.'
    run bash "${SCRIPT_PATH}"
    grep -Fq '[local] w1: 429 で停止' <(calls)
}

@test "[common] herdr-meta-patrol classifies stopped-agent error texts" {
    local latest="${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    stopped_worker idle '■ unexpected status 429 Too Many Requests: {"error":{"message":"spending limit exceeded"}}'
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] w1: 429 で停止（Gateway 予算）' "${latest}"

    stopped_worker idle "■ You've hit your usage limit. Try again in 3 hours."
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] w1: 利用上限で停止' "${latest}"

    stopped_worker idle '  ⎿  5-hour limit reached ∙ resets 3am'
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] w1: 利用上限で停止' "${latest}"

    stopped_worker idle '■ Quota exceeded. Check your plan and billing details.'
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] w1: API 制限で停止' "${latest}"
}

@test "[common] herdr-meta-patrol reports API error lines on working and blocked agents" {
    local latest="${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    stopped_worker working '■ exceeded retry limit, last status: 429 Too Many Requests'
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] w1: 429 で停止' "${latest}"

    stopped_worker blocked '■ exceeded retry limit, last status: 429 Too Many Requests'
    bash "${SCRIPT_PATH}"
    grep -Fxq '[local] blocked: w1 p1' "${latest}"
    grep -Fxq '[local] w1: 429 で停止' "${latest}"
}

@test "[common] herdr-meta-patrol reports a working agent stuck reconnecting after a 429" {
    local latest="${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    jq -n '{result:{agents:[{name:"w1",pane_id:"p1",agent_status:"working"}]}}' > "${FAKE_AGENTS}"
    printf '%s\n' '• Reading the wiki pages' '◦ Reconnecting... 1/5 (12s • esc to interrupt)' '  └ stream error: exceeded retry limit, last status: 429 Too Many Requests' > "${FAKE_RECENT_PANE}"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] w1: 429 で停止' "${SENDER_CALLS}"

    printf '%s\n' '• Reading the wiki pages' '◦ Reconnecting... 1/5 (3s • esc to interrupt)' > "${FAKE_RECENT_PANE}"
    run bash "${SCRIPT_PATH}"
    run grep -Fq 'で停止' "${latest}"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol ignores error words outside error lines" {
    local line status_value
    for line in \
        '• The worker showed "Reconnecting... 1/5" and "exceeded retry limit, last status: 429"; restarting it.' \
        'fixtures/reconnect.txt:1:Reconnecting... 1/5 and fixtures/429.json' \
        '  - Reconnecting... 1/5 and then Exceeded retry limit, last status: 429 for 4 hours.' \
        '  ⎿  API Error (429 rate_limit_error) · Retrying in 5 seconds… (attempt 1/10)' \
        '• The worker stopped with "exceeded retry limit, last status: 429 Too Many Requests"; resuming it.' \
        'mise WARN  GitHub rate limit exceeded. Resets at 01:33' \
        '  ⎿  gh: API rate limit exceeded for this address.' \
        '⏺ Committed findings.d/genai-budget-exhausted.' \
        '429 エラーで再接続を繰り返していました。budget guard と rate limit を確認します。'; do
        for status_value in idle working; do
            stopped_worker "${status_value}" "${line}"
            run bash "${SCRIPT_PATH}"
            [ "${status}" -eq 0 ]
            run grep -Fq 'で停止' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
            [ "${status}" -ne 0 ]
        done
    done

    # A short reconnect below an unrelated earlier mention of 429.
    stopped_worker working '• Earlier the worker hit 429 and recovered.'
    printf '%s\n' '• Earlier the worker hit 429 and recovered.' '' '' '' '◦ Reconnecting... 1/5 (2s • esc to interrupt)' '  └ stream disconnected before completion' > "${FAKE_RECENT_PANE}"
    run bash "${SCRIPT_PATH}"
    run grep -Fq 'で停止' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol reports finding script lines once and skips failing scripts" {
    mkdir -p "${HERDR_META_PATROL_FINDINGS_DIR}"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "[local] extra finding A"\n' > "${HERDR_META_PATROL_FINDINGS_DIR}/ok"
    printf '#!/usr/bin/env bash\necho "[local] must not appear"\nexit 3\n' > "${HERDR_META_PATROL_FINDINGS_DIR}/broken"
    printf 'not executable\n' > "${HERDR_META_PATROL_FINDINGS_DIR}/README"
    chmod +x "${HERDR_META_PATROL_FINDINGS_DIR}/ok" "${HERDR_META_PATROL_FINDINGS_DIR}/broken"
    run bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    grep -Fq '[local] extra finding A' <(calls)
    run grep -Fq 'must not appear' <(calls)
    [ "${status}" -ne 0 ]
    run grep -Fq 'not executable' <(calls)
    [ "${status}" -ne 0 ]

    ack_all
    run bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]
}

# @description Move every first-seen time in still.tsv back by the given seconds.
function age_still() {
    awk -F '\t' -v OFS='\t' -v d="$1" '{ $4 = $4 - d; print }' "${HERDR_META_PATROL_STATE_DIR}/still.tsv" > "${BATS_TEST_TMPDIR}/still.tmp"
    cat "${BATS_TEST_TMPDIR}/still.tmp" > "${HERDR_META_PATROL_STATE_DIR}/still.tsv"
}

@test "[common] herdr-meta-patrol reports a working agent whose pane has not changed, once until it changes" {
    stopped_worker working '• Running tests' '◦ Working (12m 03s • esc to interrupt)'
    printf '%s\n' '• Waiting for the job' '◦ Working (12m 03s • esc to interrupt)' > "${FAKE_RECENT_PANE}"
    bash "${SCRIPT_PATH}"
    run grep -Fq '動きなし' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]

    age_still 1300
    printf '%s\n' '• Waiting for the job' '⠹ Working (33m 41s • esc to interrupt)' > "${FAKE_RECENT_PANE}"
    bash "${SCRIPT_PATH}"
    grep -Fq '[local] w1: 20 分動きなし' <(calls)

    ack_all
    bash "${SCRIPT_PATH}"
    [ -z "$(calls)" ]

    printf '%s\n' '• Job finished, writing the report' '◦ Working (34m 02s • esc to interrupt)' > "${FAKE_RECENT_PANE}"
    bash "${SCRIPT_PATH}"
    run grep -Fq '動きなし' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol does not report idle agents or recent changes as no progress" {
    stopped_worker idle '• Done.'
    bash "${SCRIPT_PATH}"
    [ ! -s "${HERDR_META_PATROL_STATE_DIR}/still.tsv" ]

    stopped_worker working '• Step one'
    bash "${SCRIPT_PATH}"
    age_still 600
    bash "${SCRIPT_PATH}"
    run grep -Fq '動きなし' "${HERDR_META_PATROL_STATE_DIR}/latest.txt"
    [ "${status}" -ne 0 ]
}

@test "[common] herdr-meta-patrol keeps first-seen times for a machine that could not be read" {
    export FAKE_MACHINE_LIST='[{"label":"remote","enabled":true}]'
    stopped_worker working '• Step one'
    bash "${SCRIPT_PATH}"
    grep -q "^remote	p1	" "${HERDR_META_PATROL_STATE_DIR}/still.tsv"
    age_still 1300
    touch "${FAKE_REMOTE_DOWN}"
    bash "${SCRIPT_PATH}"
    grep -Fq '[local] w1: 20 分動きなし' <(calls)
    run grep -Fq '[remote] w1: 20 分動きなし' <(calls)
    [ "${status}" -ne 0 ]
    [ "$(awk -F '\t' '$1 == "remote"' "${HERDR_META_PATROL_STATE_DIR}/still.tsv" | wc -l)" -eq 1 ]
}
