#!/usr/bin/env bash

# @file home/dot_claude/hooks/executable_herdr-meta-turn-gate.sh
# @brief Block Meta from stopping with unread patrol messages or uncollected workers.
# @description
#   This hook is installed for Claude Code sessions but acts only when the
#   current Herdr pane uniquely belongs to the agent named `meta`. It checks the
#   durable patrol queue, the queue waiter process for this pane, and the worker
#   lifecycle registry. One Stop-hook continuation is allowed to avoid a loop.

set -u

input="$(cat)" || exit 0
stop_hook_active="$(jq -r '.stop_hook_active // false' <<< "${input}" 2> /dev/null)" || exit 0
[[ "${stop_hook_active}" == 'true' ]] && exit 0
[[ "${HERDR_ENV:-}" == '1' && -n "${HERDR_PANE_ID:-}" ]] || exit 0

agents_json="$(herdr agent list 2> /dev/null)" || exit 0
meta_count="$(jq -r --arg pane "${HERDR_PANE_ID}" '[.result.agents[]? | select(.name == "meta" and .pane_id == $pane)] | length' <<< "${agents_json}" 2> /dev/null)" || exit 0
[[ "${meta_count}" == '1' ]] || exit 0
meta_terminal="$(jq -r --arg pane "${HERDR_PANE_ID}" '.result.agents[] | select(.name == "meta" and .pane_id == $pane) | .terminal_id // empty' <<< "${agents_json}" 2> /dev/null)" || exit 0
[[ -n "${meta_terminal}" ]] || exit 0

reasons=()
queue_command="${HERDR_META_PATROL_QUEUE_COMMAND:-herdr-meta-patrol-queue}"
queue_records=""
if ! queue_records="$("${queue_command}" read --limit 1 2> /dev/null)"; then
    reasons+=("The patrol queue could not be checked; retry 'herdr-meta-patrol-queue read' and handle its records before stopping.")
elif ! unread_count="$(jq -sr 'length' <<< "${queue_records}" 2> /dev/null)"; then
    reasons+=("The patrol queue returned unreadable data; inspect it and handle any records before stopping.")
elif ((unread_count > 0)); then
    reasons+=("The patrol queue has unread records; run 'herdr-meta-patrol-queue read', handle every visible record, then acknowledge the highest sequence only after handling it.")
fi

waiter_found=0
queue_state_dir="${HERDR_META_PATROL_STATE_DIR:-${HOME}/.local/state/herdr-meta-patrol}"
waiters_dir="${queue_state_dir}/waiters"
if [[ -d "${waiters_dir}" && ! -L "${waiters_dir}" ]]; then
    shopt -s nullglob
    for waiter_marker in "${waiters_dir}/${HERDR_PANE_ID}."*.pid; do
        [[ -f "${waiter_marker}" && ! -L "${waiter_marker}" ]] || continue
        waiter_pid="$(cat "${waiter_marker}" 2> /dev/null)" || continue
        [[ "${waiter_pid}" =~ ^[0-9]+$ ]] || continue
        kill -0 "${waiter_pid}" 2> /dev/null || continue
        waiter_command="$(ps -ww -o command= -p "${waiter_pid}" 2> /dev/null)" || continue
        if [[ "${waiter_command}" == *herdr-meta-patrol-queue* && "${waiter_command}" =~ [[:space:]]wait([[:space:]]|$) ]]; then
            waiter_found=1
            break
        fi
    done
    shopt -u nullglob
fi
if ((waiter_found == 0)); then
    reasons+=("No 'herdr-meta-patrol-queue wait' process is running for this Meta pane; start it as a background command in this session.")
fi

state_dir="${HERDR_WORKER_LIFECYCLE_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/herdr-worker-lifecycle}"
records_file="${state_dir}/workers.tsv"
if [[ -L "${records_file}" || (-e "${records_file}" && (! -f "${records_file}" || ! -r "${records_file}")) ]]; then
    reasons+=("The worker lifecycle registry is not a readable regular file; inspect it before stopping.")
elif [[ -f "${records_file}" ]]; then
    if ! awk -F '\t' 'NF != 9 || $1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || ($9 != "started" && $9 != "collected") { bad = 1 } END { exit bad ? 1 : 0 }' "${records_file}"; then
        reasons+=("The worker lifecycle registry is malformed; inspect and reconcile it before stopping.")
    else
        pending_workers="$(awk -F '\t' -v owner_pane="${HERDR_PANE_ID}" -v owner_terminal="${meta_terminal}" '$1 == "meta" && $2 == owner_pane && $3 == owner_terminal && $9 == "started" { print $5 "\t" $6 "\t" $7 "\t" $8 }' "${records_file}")"
        while IFS=$'\t' read -r worker_name worker_terminal worker_tab worker_pane; do
            [[ -n "${worker_name:-}" ]] || continue
            worker_matches="$(jq -c --arg name "${worker_name}" --arg terminal "${worker_terminal}" --arg tab "${worker_tab}" --arg pane "${worker_pane}" '[.result.agents[]? | select(.name == $name and .terminal_id == $terminal and .tab_id == $tab and .pane_id == $pane)]' <<< "${agents_json}" 2> /dev/null)" || {
                reasons+=("The state of worker ${worker_name} could not be checked; read its transcript and reconcile its result.")
                continue
            }
            worker_count="$(jq -r 'length' <<< "${worker_matches}" 2> /dev/null)" || worker_count=0
            if [[ "${worker_count}" != '1' ]]; then
                reasons+=("Worker ${worker_name} has no unique live Herdr match; inspect its registry entry and reconcile its result.")
                continue
            fi
            worker_status="$(jq -r '.[0].agent_status // "unknown"' <<< "${worker_matches}" 2> /dev/null)" || worker_status=unknown
            case "${worker_status}" in
            idle | done)
                lifecycle_helper="${HOME}/.agents/skills/shunk031-herdr-orchestrate-workers/scripts/herdr-worker-lifecycle.sh"
                reasons+=("Worker ${worker_name} is ${worker_status} without a collected result; inspect its transcript and deliverable, finish any pending dispatch or record its DONE or BLOCKED result, then collect it with '${lifecycle_helper} collect ${worker_name}' when safe.")
                ;;
            esac
        done <<< "${pending_workers}"
    fi
fi

((${#reasons[@]} > 0)) || exit 0
reason="Meta must resolve this Stop-hook check before ending the turn: $(printf '%s; ' "${reasons[@]}")"
jq -cn --arg reason "${reason}" '{decision: "block", reason: $reason}'
