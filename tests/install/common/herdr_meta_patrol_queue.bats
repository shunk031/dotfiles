#!/usr/bin/env bats

readonly QUEUE_PATH="./home/private_dot_local/private_bin/exact_common/executable_herdr-meta-patrol-queue"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export HERDR_META_PATROL_STATE_DIR="${BATS_TEST_TMPDIR}/state"
    export HERDR_META_PATROL_QUEUE_POLL=0.1
    export NOTIFY_LOG="${BATS_TEST_TMPDIR}/notify.log"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/herdr" << 'STUB'
#!/usr/bin/env bash
[[ "$1 $2" == "notification show" ]] && printf '%s\n' "$*" >> "${NOTIFY_LOG}"
exit 0
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/herdr"
    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH
}

function queue() {
    bash "${QUEUE_PATH}" "$@"
}

@test "[common] herdr-meta-patrol-queue appends records with increasing sequence numbers" {
    queue add --kind findings --from orch $'line one\nline two'
    queue add second
    run queue read
    [ "${status}" -eq 0 ]
    [ "$(jq -s 'map(.seq)' -c <<< "${output}")" = '[1,2]' ]
    [ "$(jq -rs '.[0].text' <<< "${output}")" = $'line one\nline two' ]
    [ "$(jq -rs '.[0].kind + " " + .[0].from' <<< "${output}")" = 'findings orch' ]
    [ "$(jq -rs '.[1].kind + " " + .[1].from' <<< "${output}")" = 'message patrol' ]
}

@test "[common] herdr-meta-patrol-queue keeps sequence numbers unique under concurrent appends" {
    local i
    for i in $(seq 1 20); do
        queue add "item ${i}" &
    done
    wait
    [ "$(queue read --limit 20 | jq -s '[length, (map(.seq) | unique | length), (map(.seq) | max)]' -c)" = '[20,20,20]' ]
}

@test "[common] herdr-meta-patrol-queue reads at most ten records by default and advances in batches" {
    local i
    for i in $(seq 1 12); do queue add "item ${i}"; done

    [ "$(queue read | jq -s '[length, .[0].seq, .[-1].seq]' -c)" = '[10,1,10]' ]
    queue ack 10
    [ "$(queue read | jq -s '[length, .[0].seq, .[-1].seq]' -c)" = '[2,11,12]' ]
}

@test "[common] herdr-meta-patrol-queue compact read keeps the latest sender status and every other message" {
    queue add --from worker-a 'STATUS worker-a: task preparing'
    queue add --from worker-b 'STATUS worker-b: task reviewing'
    queue add --from worker-a 'STATUS worker-a: task testing'
    queue add --from worker-a 'BLOCKED worker-a: need input'
    queue add --from worker-a 'STATUS worker-a: task done'
    queue add --from worker-a 'ordinary message'
    queue add --from worker-a 'DONE worker-a: task complete'

    [ "$(queue read --compact-status | jq -s '[.[].seq]' -c)" = '[2,4,5,6,7]' ]
    queue ack "$(queue read --compact-status | jq -r '.seq' | tail -n 1)"
    [ -z "$(queue read)" ]
    [ "$(jq -s 'length' "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl")" = 7 ]
}

@test "[common] herdr-meta-patrol-queue compacts only inside the selected batch" {
    queue add --from worker-a 'STATUS worker-a: step one'
    queue add --from worker-a 'STATUS worker-a: step two'
    queue add --from worker-a 'STATUS worker-a: step three'

    [ "$(queue read --limit 2 --compact-status | jq -s '[.[].seq]' -c)" = '[2]' ]
    queue ack 2
    [ "$(queue read --limit 2 --compact-status | jq -s '[.[].seq]' -c)" = '[3]' ]
}

@test "[common] herdr-meta-patrol-queue does not compact a status with a mismatched sender" {
    queue add --from worker-a 'STATUS worker-b: unrelated'
    queue add --from worker-a 'STATUS worker-a: task changed'
    [ "$(queue read --compact-status | jq -s '[.[].seq]' -c)" = '[1,2]' ]
}

@test "[common] herdr-meta-patrol-queue reads only unacknowledged records and caps acks" {
    queue add one
    queue add two
    queue ack 1
    [ "$(queue read | jq -r '.text')" = two ]
    queue ack 99
    [ "$(cat "${HERDR_META_PATROL_STATE_DIR}/queue.ack")" = 2 ]
    [ -z "$(queue read)" ]
    queue ack 1
    [ "$(cat "${HERDR_META_PATROL_STATE_DIR}/queue.ack")" = 2 ]
}

@test "[common] herdr-meta-patrol-queue wait exits at once for unread records and refreshes its heartbeat" {
    queue add pending
    run queue wait --max-seconds 5
    [ "${status}" -eq 0 ]
    [[ "${output}" == 'unread 1:'* ]]
    [ -e "${HERDR_META_PATROL_STATE_DIR}/waiter.heartbeat" ]
}

@test "[common] herdr-meta-patrol-queue wait wakes on a new record and times out for re-arming" {
    run queue wait --max-seconds 1
    [ "${status}" -eq 0 ]
    [[ "${output}" == 'no unread messages'* ]]

    (
        sleep 1
        queue add later
    ) &
    run queue wait --max-seconds 20
    [ "${status}" -eq 0 ]
    [[ "${output}" == 'unread 1:'* ]]
}

@test "[common] herdr-meta-patrol-queue notifies once per stale batch while no waiter polls" {
    export HERDR_META_PATROL_STALE_SECONDS=0
    queue add first
    queue notify-if-stale
    queue notify-if-stale
    [ "$(grep -c 'notification show' "${NOTIFY_LOG}")" -eq 1 ]

    queue add second
    queue notify-if-stale
    [ "$(grep -c 'notification show' "${NOTIFY_LOG}")" -eq 2 ]

    export HERDR_META_PATROL_STALE_SECONDS=600
    touch "${HERDR_META_PATROL_STATE_DIR}/waiter.heartbeat"
    queue add third
    queue notify-if-stale
    [ "$(grep -c 'notification show' "${NOTIFY_LOG}")" -eq 2 ]
}

@test "[common] herdr-meta-patrol-queue does not notify about acknowledged records" {
    export HERDR_META_PATROL_STALE_SECONDS=0
    queue add handled
    queue ack 1
    queue notify-if-stale
    [ ! -e "${NOTIFY_LOG}" ]
}

@test "[common] herdr-meta-patrol-queue trims only old acknowledged records" {
    mkdir -p "${HERDR_META_PATROL_STATE_DIR}"
    jq -cn '{seq: 1, t: 1, at: "old", kind: "message", from: "patrol", text: "old acked"}' > "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl"
    jq -cn '{seq: 2, t: 1, at: "old", kind: "message", from: "patrol", text: "old unread"}' >> "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl"
    printf '2\n' > "${HERDR_META_PATROL_STATE_DIR}/queue.seq"
    queue ack 1
    queue add new
    queue trim
    [ "$(jq -s 'map(.seq)' -c "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl")" = '[2,3]' ]
}

@test "[common] herdr-meta-patrol-queue rejects bad usage" {
    run queue add
    [ "${status}" -eq 2 ]
    run queue ack nope
    [ "${status}" -eq 2 ]
    run queue read --limit 0
    [ "${status}" -eq 2 ]
    run queue read --limit 51
    [ "${status}" -eq 2 ]
    run queue frobnicate
    [ "${status}" -eq 2 ]
}

@test "[common] herdr-meta-patrol-queue fails an append it cannot write and keeps the sequence number" {
    queue add first
    # A failing record writer stands in for an unwritable file; CI may run as root.
    local real_jq
    real_jq="$(command -v jq)"
    cat > "${BATS_TEST_TMPDIR}/bin/jq" << STUB
#!/usr/bin/env bash
[[ "\$1" != -cn ]] || exit 1
exec "${real_jq}" "\$@"
STUB
    chmod +x "${BATS_TEST_TMPDIR}/bin/jq"
    run queue add second
    rm "${BATS_TEST_TMPDIR}/bin/jq"
    [ "${status}" -ne 0 ]
    [ "$(cat "${HERDR_META_PATROL_STATE_DIR}/queue.seq")" = 1 ]
    [ "$(queue read | jq -r '.text')" = first ]
}

@test "[common] herdr-meta-patrol-queue skips a malformed line without losing unread records" {
    queue add one
    printf '{"seq": 2, "t": 1, "te\n' >> "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl"
    queue add three
    [ "$(queue read | jq -r '.text' | tr '\n' ' ')" = 'one three ' ]
    queue trim
    [ "$(queue read | jq -r '.text' | tr '\n' ' ')" = 'one three ' ]
}

@test "[common] herdr-meta-patrol-queue keeps a record appended after a line cut short" {
    queue add one
    printf '{"seq":2' >> "${HERDR_META_PATROL_STATE_DIR}/queue.jsonl"
    queue add three
    [ "$(queue read | jq -r '.text' | tr '\n' ' ')" = 'one three ' ]
}
