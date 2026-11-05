#!/usr/bin/env bats

setup() {
    export SENTENCE_LENGTH_STATE_DIR="${BATS_TEST_TMPDIR}/sentence-length-state"
    mkdir -p "${SENTENCE_LENGTH_STATE_DIR}"
    HOOK="${BATS_TEST_DIRNAME}/../../../home/private_dot_local/private_bin/exact_common/executable_markdown-sentence-length"
}

codex_event() {
    local event_name="$1"
    local session_id="$2"
    local file_path="${3:-}"

    jq -cn \
        --arg event_name "${event_name}" \
        --arg session_id "${session_id}" \
        --arg cwd "${BATS_TEST_TMPDIR}" \
        --arg file_path "${file_path}" \
        '{hook_event_name: $event_name, session_id: $session_id, cwd: $cwd, tool_name: "apply_patch", tool_use_id: "test-tool-use", tool_input: {command: ("*** Begin Patch\n*** Update File: " + $file_path + "\n*** End Patch")}}'
}

codex_stop_event() {
    local session_id="$1"
    local stop_hook_active="${2:-false}"

    jq -cn \
        --arg session_id "${session_id}" \
        --arg cwd "${BATS_TEST_TMPDIR}" \
        --argjson stop_hook_active "${stop_hook_active}" \
        '{hook_event_name: "Stop", session_id: $session_id, cwd: $cwd, stop_hook_active: $stop_hook_active}'
}

capture_baseline() {
    local session_id="$1"
    local file_path="$2"
    local payload

    payload="$(codex_event PreToolUse "${session_id}" "${file_path}")"
    run "${HOOK}" pre codex <<< "${payload}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

run_post_hook() {
    local session_id="$1"
    local file_path="$2"
    local payload

    payload="$(codex_event PostToolUse "${session_id}" "${file_path}")"
    run "${HOOK}" post codex <<< "${payload}"
}

run_stop_hook() {
    local session_id="$1"
    local stop_hook_active="${2:-false}"
    local payload

    payload="$(codex_stop_event "${session_id}" "${stop_hook_active}")"
    run "${HOOK}" stop codex <<< "${payload}"
}

@test "fails open when Node.js is unavailable" {
    local empty_bin="${BATS_TEST_TMPDIR}/empty-bin"

    mkdir -p "${empty_bin}"
    run /usr/bin/env -i "PATH=${empty_bin}" "${HOOK}" stop codex <<< '{}'
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "fails open when textlint cannot run" {
    local file_path="${BATS_TEST_TMPDIR}/textlint-failure.md"
    local session_id="textlint-failure"
    local fake_bin="${BATS_TEST_TMPDIR}/fake-bin"

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    node -e 'process.stdout.write("x".repeat(200) + ".\n")' > "${file_path}"
    mkdir -p "${fake_bin}"
    cat > "${fake_bin}/npm" << 'EOF'
#!/bin/sh
exit 2
EOF
    chmod +x "${fake_bin}/npm"
    PATH="${fake_bin}:${PATH}"
    export PATH

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "does not repeat a Stop block when stop_hook_active is true" {
    local file_path="${BATS_TEST_TMPDIR}/active-stop.md"
    local session_id="active-stop"
    local fake_bin="${BATS_TEST_TMPDIR}/fake-bin"
    local marker="${BATS_TEST_TMPDIR}/npm-called"

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    node -e 'process.stdout.write("x".repeat(200) + ".\n")' > "${file_path}"
    mkdir -p "${fake_bin}"
    cat > "${fake_bin}/npm" << 'EOF'
#!/bin/sh
printf called > "${STOP_HOOK_NPM_MARKER}"
exit 2
EOF
    chmod +x "${fake_bin}/npm"
    export STOP_HOOK_NPM_MARKER="${marker}"
    PATH="${fake_bin}:${PATH}"
    export PATH

    run_stop_hook "${session_id}" true
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ ! -e "${marker}" ]
}

@test "blocks a newly edited long sentence through PostToolUse and Stop" {
    local file_path="${BATS_TEST_TMPDIR}/edited.md"
    local session_id="edited-long-sentence"
    local long_sentence

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${file_path}"

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"${file_path}"* ]]
    [[ "${output}" == *"Line: 1"* ]]
    [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    [[ "${output}" == *"${long_sentence}"* ]]

    run_stop_hook "${session_id}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]

    printf 'Short sentence.\n' > "${file_path}"
    run_stop_hook "${session_id}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "does not block an unrelated edit beside a pre-existing long sentence" {
    local file_path="${BATS_TEST_TMPDIR}/pre-existing.md"
    local session_id="pre-existing-long-sentence"
    local long_sentence

    long_sentence="$(node -e 'process.stdout.write("p".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    printf '%s\n\nAnother short sentence.\n' "${long_sentence}" > "${file_path}"

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run_stop_hook "${session_id}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a long sentence wrapped in sentence-length disable comments" {
    local file_path="${BATS_TEST_TMPDIR}/disabled.md"
    local session_id="disabled-long-sentence"
    local long_sentence

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    long_sentence="$(node -e 'process.stdout.write("d".repeat(200) + ".")')"
    printf 'Short sentence.\n\n<!-- textlint-disable sentence-length -->\n\n%s\n\n<!-- textlint-enable sentence-length -->\n' \
        "${long_sentence}" > "${file_path}"

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run_stop_hook "${session_id}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "applies the Japanese 100 and non-Japanese 200 codepoint limits" {
    local file_path="${BATS_TEST_TMPDIR}/language-limits.md"
    local session_id="language-specific-limits"
    local english_under_limit japanese mixed

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    english_under_limit="$(node -e 'process.stdout.write("e".repeat(179) + ".")')"
    japanese="$(node -e 'process.stdout.write("あ".repeat(100) + "。")')"
    mixed="$(node -e 'process.stdout.write("English " + "あ".repeat(92) + "。")')"
    {
        printf '%s\n\n' "${english_under_limit}"
        node -e 'process.stdout.write("t".repeat(200) + ".\n\n")'
        printf '%s\n\n%s\n' "${japanese}" "${mixed}"
    } > "${file_path}"

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    [[ "${output}" == *"Length: 101 codepoints; limit: 100"* ]]
    [[ "${output}" != *"${english_under_limit}"* ]]
    [[ "${output}" == *"${japanese}"* ]]
    [[ "${output}" == *"${mixed}"* ]]
}
