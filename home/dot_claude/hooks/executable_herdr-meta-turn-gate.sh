#!/usr/bin/env bash

# @file home/dot_claude/hooks/executable_herdr-meta-turn-gate.sh
# @brief Block Meta from stopping with unread patrol messages or uncollected workers.
# @description
#   This hook acts only when the current Herdr pane uniquely belongs to `meta`.
#   Once identity is proven, every failed check blocks with recovery guidance.
#   Repeated identical reasons block three times, then allow with an audit warning.

set -u
set -o pipefail

input="$(cat 2> /dev/null)" || input=''
[[ "${HERDR_ENV:-}" == '1' && -n "${HERDR_PANE_ID:-}" ]] || exit 0

# Identity lookup is the only part allowed to fail open.
if ! agents_json="$(herdr agent list 2> /dev/null)"; then
    exit 0
fi
if ! pane_agents="$(jq -ce --arg pane "${HERDR_PANE_ID}" '[.result.agents[]? | select(.pane_id == $pane)]' <<< "${agents_json}" 2> /dev/null)"; then
    exit 0
fi
if ! pane_agent_count="$(jq -er 'length' <<< "${pane_agents}" 2> /dev/null)"; then
    exit 0
fi
[[ "${pane_agent_count}" == '1' ]] || exit 0
if ! meta_name="$(jq -er '.[0].name // empty' <<< "${pane_agents}" 2> /dev/null)"; then
    exit 0
fi
[[ "${meta_name}" == 'meta' ]] || exit 0

check_errors=()
blockers=()
check_error_count=0
blocker_count=0

function add_check_error() {
    check_errors+=("$1; recovery: $2")
    check_error_count=$((check_error_count + 1))
}

function add_blocker() {
    blockers+=("$1; recovery: $2")
    blocker_count=$((blocker_count + 1))
}

function emit_block() {
    jq -cn --arg reason "$1" '{decision: "block", reason: $reason}'
}

function fail_closed() {
    emit_block "gate cannot verify: $1; recovery: $2"
    exit 0
}

# Validate the Stop payload only after Meta is known to be in this pane.
stop_hook_active=false
session_id=''
if ! jq -e 'type == "object"' <<< "${input}" > /dev/null 2>&1; then
    add_check_error "the Claude Stop payload is not a JSON object" "resume the Claude session and retry the Stop hook"
else
    active_value="$(jq -r 'if has("stop_hook_active") then (if (.stop_hook_active | type) == "boolean" then .stop_hook_active else "invalid" end) else "invalid" end' <<< "${input}" 2> /dev/null)" || active_value=invalid
    if [[ "${active_value}" == 'true' || "${active_value}" == 'false' ]]; then
        stop_hook_active="${active_value}"
    else
        add_check_error "stop_hook_active is missing or invalid" "resume the Claude session and retry the Stop hook"
    fi
    session_type="$(jq -r 'if has("session_id") then (.session_id | type) else "missing" end' <<< "${input}" 2> /dev/null)" || session_type=invalid
    if [[ "${session_type}" != 'string' ]]; then
        add_check_error "session_id is missing or is not a string" "resume the Claude session and retry the Stop hook"
    elif ! session_id="$(jq -r '.session_id' <<< "${input}" 2> /dev/null)" || [[ -z "${session_id}" ]]; then
        add_check_error "session_id is empty or could not be read" "resume the Claude session and retry the Stop hook"
        session_id=''
    elif [[ ! "${session_id}" =~ ^[A-Za-z0-9_-]+$ ]]; then
        add_check_error "session_id has an invalid format" "resume the Claude session and retry the Stop hook"
        session_id=''
    fi
fi

meta_terminal="$(jq -r '.[0].terminal_id // empty' <<< "${pane_agents}" 2> /dev/null)" || meta_terminal=''
if [[ -z "${meta_terminal}" ]]; then
    add_check_error "Meta has no terminal_id in the Herdr agent list" "run 'herdr agent list' and reconcile Meta's pane ownership"
fi

queue_command="${HERDR_META_PATROL_QUEUE_COMMAND:-herdr-meta-patrol-queue}"
if ! queue_records="$("${queue_command}" read --limit 50 2> /dev/null)"; then
    add_check_error "the patrol queue could not be read" "run 'herdr-meta-patrol-queue read' and inspect the queue state"
elif ! unread_count="$(jq -sr 'if all(.[]; type == "object" and (.seq | type) == "number" and (.text | type) == "string") then length else error("invalid queue record") end' <<< "${queue_records}" 2> /dev/null)"; then
    add_check_error "the patrol queue returned unparsable or malformed records" "run 'herdr-meta-patrol-queue read' and repair or acknowledge its records"
elif ((unread_count > 0)); then
    add_blocker "the patrol queue has unread records" "run 'herdr-meta-patrol-queue read', handle each record, then acknowledge the highest handled sequence"
fi

queue_state_dir="${HERDR_META_PATROL_STATE_DIR:-${HOME}/.local/state/herdr-meta-patrol}"
waiters_dir="${queue_state_dir}/waiters"
if [[ -L "${waiters_dir}" || ! -d "${waiters_dir}" || ! -r "${waiters_dir}" || ! -x "${waiters_dir}" ]]; then
    add_check_error "the queue waiter directory is missing, unreadable, or malformed" "create '${waiters_dir}' and start 'herdr-meta-patrol-queue wait' in this pane"
else
    shopt -s nullglob
    waiter_markers=("${waiters_dir}/${HERDR_PANE_ID}."*.pid)
    shopt -u nullglob
    if ((${#waiter_markers[@]} == 0)); then
        add_blocker "no queue waiter marker exists for this Meta pane" "start 'herdr-meta-patrol-queue wait' as a background command in this session"
    else
        waiter_found=0
        for waiter_marker in "${waiter_markers[@]}"; do
            if [[ -L "${waiter_marker}" || ! -f "${waiter_marker}" || ! -r "${waiter_marker}" ]]; then
                add_check_error "waiter marker '${waiter_marker}' is not a readable regular file" "remove the stale marker and restart 'herdr-meta-patrol-queue wait'"
                continue
            fi
            if ! waiter_pid="$(cat "${waiter_marker}" 2> /dev/null)"; then
                add_check_error "waiter marker '${waiter_marker}' could not be read" "restart 'herdr-meta-patrol-queue wait' in this pane"
                continue
            fi
            if [[ ! "${waiter_pid}" =~ ^[0-9]+$ ]]; then
                add_check_error "waiter marker '${waiter_marker}' has an invalid PID" "remove the stale marker and restart 'herdr-meta-patrol-queue wait'"
                continue
            fi
            if ! kill -0 "${waiter_pid}" 2> /dev/null; then
                add_check_error "waiter PID ${waiter_pid} is not running" "remove the stale marker and restart 'herdr-meta-patrol-queue wait'"
                continue
            fi
            if ! waiter_command="$(ps -ww -o command= -p "${waiter_pid}" 2> /dev/null)" || [[ -z "${waiter_command}" ]]; then
                add_check_error "waiter PID ${waiter_pid} could not be inspected" "run 'ps -ww -o command= -p ${waiter_pid}' and restart the queue waiter"
                continue
            fi
            if [[ "${waiter_command}" == *herdr-meta-patrol-queue* && "${waiter_command}" =~ [[:space:]]wait([[:space:]]|$) ]]; then
                waiter_found=1
            else
                add_check_error "waiter PID ${waiter_pid} is not running the queue wait command" "restart 'herdr-meta-patrol-queue wait' in this pane"
            fi
        done
        ((waiter_found == 1)) || add_blocker "no live queue waiter exists for this Meta pane" "start 'herdr-meta-patrol-queue wait' as a background command in this session"
    fi
fi

lifecycle_helper="${HOME}/.agents/skills/shunk031-herdr-orchestrate-workers/scripts/herdr-worker-lifecycle.sh"
state_dir="${HERDR_WORKER_LIFECYCLE_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/herdr-worker-lifecycle}"
state_parent="${state_dir%/*}"
records_file="${state_dir}/workers.tsv"
if [[ -L "${state_parent}" || ! -d "${state_parent}" || ! -r "${state_parent}" || ! -x "${state_parent}" ]]; then
    add_check_error "the worker lifecycle parent '${state_parent}' is missing or inaccessible" "restore it, then run '${lifecycle_helper} audit'"
elif [[ -L "${state_dir}" || ! -d "${state_dir}" || ! -r "${state_dir}" || ! -x "${state_dir}" ]]; then
    add_check_error "the worker lifecycle registry directory '${state_dir}' is missing or malformed" "restore it, then run '${lifecycle_helper} audit'"
elif [[ -L "${records_file}" || ! -f "${records_file}" || ! -r "${records_file}" ]]; then
    add_check_error "the worker lifecycle registry '${records_file}' is missing or not a readable regular file" "restore the registry and run '${lifecycle_helper} audit'"
else
    if ! pending_workers="$(awk -F '\t' 'NF != 9 || $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || ($9 != "started" && $9 != "collected") { bad = 1; next } $1 == "meta" && $2 == owner_pane && $3 == owner_terminal && $9 == "started" { print $5 "\t" $6 "\t" $7 "\t" $8 } END { exit bad ? 1 : 0 }' owner_pane="${HERDR_PANE_ID}" owner_terminal="${meta_terminal}" "${records_file}" 2> /dev/null)"; then
        add_check_error "the worker lifecycle registry is unparsable or contains unexpected statuses" "repair '${records_file}', then run '${lifecycle_helper} audit'"
    else
        while IFS=$'\t' read -r worker_name worker_terminal worker_tab worker_pane; do
            [[ -n "${worker_name:-}" ]] || continue
            if ! worker_matches="$(jq -ce --arg name "${worker_name}" --arg terminal "${worker_terminal}" --arg tab "${worker_tab}" --arg pane "${worker_pane}" '[.result.agents[]? | select(.name == $name and .terminal_id == $terminal and .tab_id == $tab and .pane_id == $pane)]' <<< "${agents_json}" 2> /dev/null)"; then
                add_check_error "the live state of worker '${worker_name}' could not be parsed" "run 'herdr agent list' and reconcile '${worker_name}'"
                continue
            fi
            if ! worker_count="$(jq -er 'length' <<< "${worker_matches}" 2> /dev/null)"; then
                add_check_error "the live state of worker '${worker_name}' could not be counted" "run 'herdr agent list' and reconcile '${worker_name}'"
                continue
            fi
            if [[ "${worker_count}" != '1' ]]; then
                add_check_error "worker '${worker_name}' has no unique live Herdr match" "run 'herdr agent list' and reconcile '${worker_name}'"
                continue
            fi
            if ! worker_status="$(jq -er '.[0].agent_status | strings' <<< "${worker_matches}" 2> /dev/null)"; then
                add_check_error "worker '${worker_name}' has no readable Herdr status" "run 'herdr agent list' and reconcile '${worker_name}'"
                continue
            fi
            if [[ "${worker_status}" != 'working' && "${worker_status}" != 'blocked' && "${worker_status}" != 'idle' && "${worker_status}" != 'done' ]]; then
                add_check_error "worker '${worker_name}' has unexpected status '${worker_status}'" "run 'herdr agent list' and '${lifecycle_helper} audit'"
            else
                add_blocker "worker '${worker_name}' has an uncollected started lifecycle record (status ${worker_status})" "inspect its transcript and result, then collect it with '${lifecycle_helper} collect ${worker_name}' when safe"
            fi
        done <<< "${pending_workers}"
    fi
fi

((check_error_count + blocker_count > 0)) || exit 0
reason=''
if ((check_error_count > 0)); then
    for check_error in "${check_errors[@]}"; do
        reason+="gate cannot verify: ${check_error}. "
    done
fi
if ((blocker_count > 0)); then
    for blocker in "${blockers[@]}"; do
        reason+="Meta must resolve: ${blocker}. "
    done
fi

if [[ -n "${session_id}" ]]; then
    session_key="$(printf '%s' "${session_id}" | cksum | awk '{print $1 "-" $2}')" || fail_closed "the retry session key could not be generated" "retry the Claude Stop hook"
else
    session_key="pane-$(printf '%s' "${HERDR_PANE_ID}" | cksum | awk '{print $1 "-" $2}')" || fail_closed "the pane retry key could not be generated" "run 'herdr agent list' and retry the Stop hook"
fi
reason_fingerprint="$(printf '%s' "${reason}" | cksum | awk '{print $1 ":" $2}')" || fail_closed "the retry reason fingerprint could not be generated" "retry the Claude Stop hook"

function prepare_state_dir() {
    local directory="$1"
    [[ ! -L "${directory}" ]] || return 1
    mkdir -p "${directory}" 2> /dev/null || return 1
    [[ -d "${directory}" && ! -L "${directory}" && -r "${directory}" && -w "${directory}" && -x "${directory}" ]] || return 1
    chmod 700 "${directory}" 2> /dev/null || return 1
}

function write_retry_state() {
    local directory="$1"
    local destination="${directory}/${session_key}.json"
    local temporary="${destination}.$$.tmp"
    [[ ! -L "${destination}" && (! -e "${destination}" || -f "${destination}") ]] || return 1
    [[ ! -L "${temporary}" && ! -e "${temporary}" ]] || return 1
    if ! (umask 077 && jq -cn --arg fingerprint "${reason_fingerprint}" --argjson count "${block_count}" '{reason_fingerprint: $fingerprint, consecutive_blocks: $count}' > "${temporary}"); then
        rm -f "${temporary}"
        return 1
    fi
    if [[ ! -f "${temporary}" || -L "${temporary}" || ! -r "${temporary}" ]]; then
        rm -f "${temporary}"
        return 1
    fi
    if ! mv -f "${temporary}" "${destination}" || [[ ! -f "${destination}" || -L "${destination}" ]]; then
        rm -f "${temporary}"
        return 1
    fi
}

if ! state_uid="$(id -u 2> /dev/null)" || [[ ! "${state_uid}" =~ ^[0-9]+$ ]]; then
    fail_closed "the per-user retry state directory could not be selected" "repair the shell environment and retry the Stop hook"
fi
primary_state_dir="${HERDR_META_PATROL_STATE_DIR:-${HOME}/.local/state/herdr-meta-patrol}/stop-gate"
fallback_state_dir="${TMPDIR:-/tmp}/herdr-meta-turn-gate-${state_uid}"
if prepare_state_dir "${primary_state_dir}"; then
    gate_state_dir="${primary_state_dir}"
elif prepare_state_dir "${fallback_state_dir}"; then
    gate_state_dir="${fallback_state_dir}"
else
    fail_closed "retry state cannot be created in '${primary_state_dir}' or '${fallback_state_dir}'" "create a writable retry state directory with 'mkdir -p ${primary_state_dir}'"
fi
fallback_state_file="${fallback_state_dir}/${session_key}.json"
if [[ "${gate_state_dir}" == "${primary_state_dir}" && (-e "${fallback_state_file}" || -L "${fallback_state_file}") ]]; then
    if ! prepare_state_dir "${fallback_state_dir}"; then
        fail_closed "the existing fallback retry state cannot be accessed" "repair '${fallback_state_dir}'"
    fi
    gate_state_dir="${fallback_state_dir}"
fi
state_file="${gate_state_dir}/${session_key}.json"
log_file="${gate_state_dir}/audit.log"
if [[ -L "${state_file}" || (-e "${state_file}" && (! -f "${state_file}" || ! -r "${state_file}")) ]]; then
    fail_closed "retry state '${state_file}' is not a readable regular file" "remove or repair '${state_file}', then retry the Stop hook"
fi
state_exists=0
saved_reason=''
saved_count=0
if [[ -f "${state_file}" ]]; then
    if ! jq -e 'type == "object" and (.reason_fingerprint | type) == "string" and (.consecutive_blocks | type) == "number" and (.consecutive_blocks | floor) == .consecutive_blocks and (.consecutive_blocks >= 1 and .consecutive_blocks <= 3)' "${state_file}" > /dev/null 2>&1; then
        fail_closed "retry state '${state_file}' is unparsable or malformed" "repair or remove '${state_file}', then retry the Stop hook"
    fi
    state_exists=1
    saved_reason="$(jq -r '.reason_fingerprint' "${state_file}" 2> /dev/null)" || fail_closed "retry state '${state_file}' could not be read" "repair '${state_file}'"
    saved_count="$(jq -r '.consecutive_blocks' "${state_file}" 2> /dev/null)" || fail_closed "retry state '${state_file}' could not be read" "repair '${state_file}'"
elif [[ "${stop_hook_active}" == 'true' ]]; then
    fail_closed "retry state is missing for an active Stop retry" "start a fresh Claude turn after checking the patrol state"
fi

block_count=1
if [[ "${stop_hook_active}" == 'true' && "${state_exists}" == '1' && "${saved_reason}" == "${reason_fingerprint}" ]]; then
    if ((saved_count < 3)); then
        block_count=$((saved_count + 1))
    else
        timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2> /dev/null)" || timestamp=unknown
        log_written=0
        if [[ ! -L "${log_file}" && (! -e "${log_file}" || -f "${log_file}") ]] && jq -cn --arg timestamp "${timestamp}" --arg session "${session_key}" --arg fingerprint "${reason_fingerprint}" '{timestamp: $timestamp, session_key: $session, reason_fingerprint: $fingerprint, consecutive_blocks: 3, action: "allow"}' >> "${log_file}" 2> /dev/null; then
            log_written=1
        fi
        rm -f "${state_file}" 2> /dev/null || true
        if ((log_written)); then
            message='The Meta turn gate allowed this turn to end after blocking the same unresolved condition three times; inspect the patrol state before the next turn.'
        else
            message='The Meta turn gate allowed this turn to end after three blocks, but could not append its audit log; inspect the patrol state before the next turn.'
        fi
        jq -cn --arg message "${message}" '{systemMessage: $message}'
        exit 0
    fi
fi

if ! write_retry_state "${gate_state_dir}"; then
    if [[ "${gate_state_dir}" != "${fallback_state_dir}" ]] && prepare_state_dir "${fallback_state_dir}"; then
        if [[ -L "${fallback_state_file}" || (-e "${fallback_state_file}" && ! -f "${fallback_state_file}") ]]; then
            fail_closed "fallback retry state '${fallback_state_file}' is not a regular file" "repair '${fallback_state_file}'"
        fi
        if ! write_retry_state "${fallback_state_dir}"; then
            fail_closed "retry state could not be written in either location" "make '${primary_state_dir}' or '${fallback_state_dir}' writable"
        fi
        gate_state_dir="${fallback_state_dir}"
    else
        fail_closed "retry state could not be written in '${gate_state_dir}' or '${fallback_state_dir}'" "make one of those directories writable"
    fi
fi

emit_block "${reason}"
