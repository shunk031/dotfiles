#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/private_dot_local/private_bin/exact_common/executable_claude-subagent-feed"

function setup() {
    FEED_DIR="${BATS_TEST_TMPDIR}/feed"
    mkdir -p "${FEED_DIR}"
}

function post_tool_use() {
    jq -nc \
        --arg session_id "$1" \
        --arg agent_id "$2" \
        --arg description "$3" \
        --arg subagent_type "$4" \
        --arg model "$5" \
        '{hook_event_name:"PostToolUse",session_id:$session_id,tool_name:"Agent",tool_input:{subagent_type:$subagent_type,model:$model},tool_response:{status:"async_launched",agentId:$agent_id,description:$description,resolvedModel:$model}}'
}

function subagent_stop() {
    jq -nc --arg session_id "$1" --arg agent_id "$2" \
        '{hook_event_name:"SubagentStop",session_id:$session_id,agent_id:$agent_id}'
}

@test "[common] Claude Agent async launch writes a working inbox entry" {
    local input
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet)"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]

    run jq -e '.version == 1 and .source == "claude-subagent-hook" and (.writtenAt | type == "number") and .entries == [{key:"subagent/session-1/agent-1",state:"working",title:"Review the change",detail:"Explore · sonnet",at:.entries[0].at}]' "${FEED_DIR}/subagent-session-1-agent-1.json"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude subagent title falls back through available descriptions" {
    local input
    input="$(post_tool_use session-1 response 'Response title' Explore sonnet | jq -c '.tool_input.description = "Input title"')"
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]

    input="$(post_tool_use session-1 input '' Explore sonnet | jq -c 'del(.tool_response.description) | .tool_input.description = "Input title"')"
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]

    input="$(post_tool_use session-1 type '' Explore sonnet | jq -c 'del(.tool_response.description) | del(.tool_input.description)')"
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]

    input="$(post_tool_use session-1 fallback '' Explore sonnet | jq -c 'del(.tool_response.description) | del(.tool_input.description) | del(.tool_input.subagent_type)')"
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]

    run jq -e -s 'map(.entries[0].title) == ["Response title", "Input title", "Explore", "subagent"]' \
        "${FEED_DIR}/subagent-session-1-response.json" \
        "${FEED_DIR}/subagent-session-1-input.json" \
        "${FEED_DIR}/subagent-session-1-type.json" \
        "${FEED_DIR}/subagent-session-1-fallback.json"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude SubagentStop marks the existing entry done" {
    local input stop_input entry_file
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet)"
    entry_file="${FEED_DIR}/subagent-session-1-agent-1.json"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    stop_input="$(subagent_stop session-1 agent-1)"
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${stop_input}"
    [ "${status}" -eq 0 ]

    run jq -e '.entries[0].state == "done" and .entries[0].title == "Review the change" and (.entries[0].at | type == "number")' "${entry_file}"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude SubagentStop without a matching entry creates no file" {
    local input
    input="$(subagent_stop session-1 agent-1)"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ -z "$(find "${FEED_DIR}" -type f -print)" ]
}

@test "[common] Claude subagent hook rejects bad JSON without writing" {
    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< '{'
    [ "${status}" -ne 0 ]
    [ -z "$(find "${FEED_DIR}" -type f -print)" ]
}

@test "[common] Claude subagent write prunes only old subagent snapshots" {
    local input old_file new_file other_file
    old_file="${FEED_DIR}/subagent-old.json"
    new_file="${FEED_DIR}/subagent-new.json"
    other_file="${FEED_DIR}/notes.json"
    : > "${old_file}"
    : > "${new_file}"
    : > "${other_file}"
    touch -t 200001010000 "${old_file}" "${other_file}"
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet)"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ ! -e "${old_file}" ]
    [ -e "${new_file}" ]
    [ -e "${other_file}" ]
    [ -e "${FEED_DIR}/subagent-session-1-agent-1.json" ]
}

@test "[common] Claude subagent PostToolUse is ignored" {
    local input
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet | jq -c '. + {agent_id:"nested-agent"}')"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ -z "$(find "${FEED_DIR}" -type f -print)" ]
}

@test "[common] Claude Agent launch with a non-async status is ignored" {
    local input
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet | jq -c '.tool_response.status = "completed"')"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ -z "$(find "${FEED_DIR}" -type f -print)" ]
}

@test "[common] Claude subagent hook is a no-op without an inbox feed directory" {
    local input missing_dir
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet)"
    missing_dir="${BATS_TEST_TMPDIR}/missing-feed"

    run env -u INBOX_FEED bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    run env INBOX_FEED="${missing_dir}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ ! -e "${missing_dir}" ]
    [ -z "$(find "${FEED_DIR}" -type f -print)" ]
}

@test "[common] Claude subagent snapshot is complete before its atomic rename" {
    local bin_dir marker input
    bin_dir="${BATS_TEST_TMPDIR}/bin"
    marker="${BATS_TEST_TMPDIR}/atomic-mv-called"
    mkdir -p "${bin_dir}"
    cat > "${bin_dir}/mv" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$1" = "-f" ]
shift
[ "$(dirname "$1")" = "$(dirname "$2")" ]
jq -e '.version == 1 and (.entries | length) == 1' "$1" > /dev/null
: > "${ATOMIC_MARKER}"
exec /bin/mv -f "$1" "$2"
EOF
    chmod +x "${bin_dir}/mv"
    input="$(post_tool_use session-1 agent-1 'Review the change' Explore sonnet)"

    run env PATH="${bin_dir}:${PATH}" ATOMIC_MARKER="${marker}" INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    [ -f "${marker}" ]
    [ -z "$(find "${FEED_DIR}" -name '.subagent-*' -print)" ]
}

@test "[common] Claude subagent ids are sanitized in snapshot filenames" {
    local input
    input="$(post_tool_use 'session/1' 'agent:2' 'Review the change' Explore sonnet)"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    run jq -e '.entries[0].key == "subagent/session/1/agent:2"' "${FEED_DIR}/subagent-session_1-agent_2.json"
    [ "${status}" -eq 0 ]
}

@test "[common] Claude subagent title and detail respect their character caps" {
    local input title detail
    title="$(printf '%0121d' 0)"
    detail="$(printf '%0601d' 0)"
    input="$(post_tool_use session-1 agent-1 "${title}" "${detail}" '')"

    run env INBOX_FEED="${FEED_DIR}" bash "${SCRIPT_PATH}" <<< "${input}"
    [ "${status}" -eq 0 ]
    run jq -e '(.entries[0].title | length) == 120 and (.entries[0].detail | length) == 600' "${FEED_DIR}/subagent-session-1-agent-1.json"
    [ "${status}" -eq 0 ]
}
