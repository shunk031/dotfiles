#!/usr/bin/env bash

# @file home/dot_config/exact_agents/skills/shunk031-orchestrate-herdr-workers/scripts/herdr-orchestrator-observer.sh
# @brief Observe fixed worker identities and coalesce bounded orchestrator nudges.
# @description
#   Scope is supplied as immutable worker, pane, and tab identities. Each sample
#   reads live Herdr state; alert and rearm memory stays in this process.

set -Eeuo pipefail

if [[ "${HERDR_ENV:-}" != 1 ]]; then
    printf '%s\n' 'observer requires HERDR_ENV=1' >&2
    exit 2
fi

ORCHESTRATOR=''
INTERVAL_SECONDS=60
STALE_SAMPLES=3
declare -a WORKER_SPECS=()
declare -A previous_fingerprint=() previous_stable=() previous_alerted=()

if (($# == 0)); then
    printf '%s\n' 'usage: herdr-orchestrator-observer.sh --orchestrator NAME --worker NAME|PANE|TAB [--worker ...] [--interval-seconds N] [--stale-samples N]' >&2
    exit 2
fi

while (($# > 0)); do
    case "$1" in
    --orchestrator)
        (($# >= 2)) || exit 2
        ORCHESTRATOR="$2"
        shift 2
        ;;
    --worker)
        (($# >= 2)) || exit 2
        WORKER_SPECS+=("$2")
        shift 2
        ;;
    --interval-seconds)
        (($# >= 2)) || exit 2
        INTERVAL_SECONDS="$2"
        shift 2
        ;;
    --stale-samples)
        (($# >= 2)) || exit 2
        STALE_SAMPLES="$2"
        shift 2
        ;;
    --help)
        printf '%s\n' 'usage: herdr-orchestrator-observer.sh --orchestrator NAME --worker NAME|PANE|TAB [--worker ...] [--interval-seconds N] [--stale-samples N]'
        exit 0
        ;;
    *)
        exit 2
        ;;
    esac
done

[[ "${ORCHESTRATOR}" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || exit 2
[[ "${INTERVAL_SECONDS}" =~ ^[1-9][0-9]*$ && "${STALE_SAMPLES}" =~ ^[1-9][0-9]*$ ]] || exit 2
((${#WORKER_SPECS[@]} == 0)) && exit 0

declare -A names=() panes=() tabs=()
for spec in "${WORKER_SPECS[@]}"; do
    IFS='|' read -r name pane tab extra <<< "${spec}"
    [[ -n "${name}" && -n "${pane}" && -n "${tab}" && -z "${extra}" ]] || exit 2
    [[ "${name}" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || exit 2
    [[ "${pane}" =~ ^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$ && "${tab}" =~ ^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$ ]] || exit 2
    [[ "${name}" != "${ORCHESTRATOR}" ]] || exit 2
    key="${name}|${pane}|${tab}"
    [[ -z "${names[${name}]-}" && -z "${panes[${pane}]-}" && -z "${tabs[${tab}]-}" ]] || exit 2
    names["${name}"]="${key}"
    panes["${pane}"]="${key}"
    tabs["${tab}"]="${key}"
done

for command in herdr jq shasum awk sleep; do
    command -v "${command}" > /dev/null || {
        printf 'observer: required command is missing: %s\n' "${command}" >&2
        exit 127
    }
done

function hash_text() {
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

function observe_once() {
    local agents spec name pane tab row status revision state_seq tab_json label transcript transcript_sha
    local normalized_status fingerprint previous stable alerted complete open_pr_wait
    local matched_workers=0
    local nudge
    local -a report_lines=() pending_names=()
    local -A next_fingerprint=() next_stable=() next_alerted=()

    agents="$(herdr agent list 2> /dev/null)" || {
        printf '%s\n' 'observer: herdr agent list failed; sample rejected' >&2
        return 1
    }
    jq -e '.result.agents | type == "array"' <<< "${agents}" > /dev/null || {
        printf '%s\n' 'observer: malformed herdr agent list; sample rejected' >&2
        return 1
    }

    for spec in "${WORKER_SPECS[@]}"; do
        IFS='|' read -r name pane tab <<< "${spec}"
        if ! row="$(jq -er --arg name "${name}" --arg pane "${pane}" --arg tab "${tab}" '
			[.result.agents[]? | select(.name == $name and .pane_id == $pane and .tab_id == $tab)]
			| if length == 1 and (.[0].agent_status | type) == "string" and
				(.[0].revision | type) == "number" and (.[0].state_change_seq | type) == "number"
			  then .[0] | [.agent_status, .revision, .state_change_seq] | @tsv
			  else error("worker identity missing or malformed") end' <<< "${agents}")"; then
            printf 'observer: live identity read failed for %s; worker skipped\n' "${name}" >&2
            continue
        fi
        IFS=$'\t' read -r status revision state_seq <<< "${row}"
        [[ "${status}" =~ ^(working|idle|done|blocked|unknown)$ && "${revision}" =~ ^[0-9]+$ && "${state_seq}" =~ ^[0-9]+$ ]] || {
            printf 'observer: malformed live state for %s; worker skipped\n' "${name}" >&2
            continue
        }
        matched_workers=$((matched_workers + 1))

        if ! tab_json="$(herdr tab get "${tab}" 2> /dev/null)" || ! label="$(jq -er '.result.tab.label | strings' <<< "${tab_json}")"; then
            printf 'observer: tab read failed for %s; worker skipped\n' "${name}" >&2
            continue
        fi
        if ! transcript="$(herdr agent read "${name}" --source recent-unwrapped --lines 80 2> /dev/null)" || [[ -z "${transcript}" ]]; then
            printf 'observer: transcript read failed for %s; worker skipped\n' "${name}" >&2
            continue
        fi
        transcript_sha="$(hash_text "${transcript}")"

        normalized_status="${status}"
        [[ "${normalized_status}" == "done" ]] && normalized_status=idle
        fingerprint="$(hash_text "${name}|${pane}|${tab}|${normalized_status}|${revision}|${state_seq}|${label}|${transcript_sha}")"
        previous="${previous_fingerprint[${name}]-}"
        if [[ "${fingerprint}" == "${previous}" ]]; then
            stable=$((${previous_stable[${name}]-0} + 1))
            alerted="${previous_alerted[${name}]-0}"
        else
            stable=1
            alerted=0
        fi
        next_fingerprint["${name}"]="${fingerprint}"
        next_stable["${name}"]="${stable}"
        next_alerted["${name}"]="${alerted}"

        complete=0
        open_pr_wait=0
        case "${label}" in
        '✅ '*) complete=1 ;;
        '⛔ review and merge PR '*) open_pr_wait=1 ;;
        esac
        if [[ "${normalized_status}" == idle && "${complete}" == 1 && "${alerted}" != 1 ]]; then
            report_lines+=("- worker=${name} pane=${pane} tab=${tab} status=idle reason=completed resource needs bounded worktree and PR reconciliation (state_change_seq=${state_seq} revision=${revision} transcript_sha=${transcript_sha})")
            pending_names+=("${name}")
        elif ((stable >= STALE_SAMPLES)) && [[ "${open_pr_wait}" != 1 && "${alerted}" != 1 ]]; then
            if [[ "${normalized_status}" == working ]]; then
                report_lines+=("- worker=${name} pane=${pane} tab=${tab} status=working reason=no lifecycle/revision/transcript movement for ${stable} samples; this may be a quiet long command, reconcile why it looks stale before prompting or killing (state_change_seq=${state_seq} revision=${revision} transcript_sha=${transcript_sha})")
            else
                report_lines+=("- worker=${name} pane=${pane} tab=${tab} status=${normalized_status} reason=no lifecycle/revision/transcript movement for ${stable} samples; reconcile a missing report or handoff (state_change_seq=${state_seq} revision=${revision} transcript_sha=${transcript_sha})")
            fi
            pending_names+=("${name}")
        fi
    done

    ((matched_workers > 0)) || {
        printf '%s\n' 'observer: no scoped workers remain; stopping' >&2
        return 3
    }
    if ((${#report_lines[@]} > 0)); then
        nudge="$(
            printf 'OBSERVER %s: bounded reconciliation required\n' "${ORCHESTRATOR}"
            printf '%s\n' "${report_lines[@]}"
            printf '%s\n' 'Reconcile Herdr state/transcript and relevant worktree/PR/CI truth; this observer is read-only and the report is not terminal.'
        )"
        if herdr agent prompt "${ORCHESTRATOR}" "${nudge}" > /dev/null 2>&1; then
            for name in "${pending_names[@]}"; do next_alerted["${name}"]=1; done
        else
            printf '%s\n' 'observer: orchestrator nudge failed; episode remains armed' >&2
        fi
    fi

    previous_fingerprint=()
    previous_stable=()
    previous_alerted=()
    for name in "${!next_fingerprint[@]}"; do
        previous_fingerprint["${name}"]="${next_fingerprint[${name}]}"
        previous_stable["${name}"]="${next_stable[${name}]}"
        previous_alerted["${name}"]="${next_alerted[${name}]}"
    done
}

trap 'exit 0' INT TERM
while :; do
    if observe_once; then
        :
    else
        status=$?
        ((status == 3)) && exit 0
    fi
    sleep "${INTERVAL_SECONDS}" &
    wait "$!" || true
done
