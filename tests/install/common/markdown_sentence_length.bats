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
    run --separate-stderr "${HOOK}" pre codex <<< "${payload}"
    [ "${status}" -eq 0 ]
    if [ -n "${output}" ]; then
        printf 'Unexpected baseline stdout: %s\nStderr: %s\n' "${output}" "${stderr}" >&2
        return 1
    fi
}

run_post_hook() {
    local session_id="$1"
    local file_path="$2"
    local payload

    payload="$(codex_event PostToolUse "${session_id}" "${file_path}")"
    run --separate-stderr "${HOOK}" post codex <<< "${payload}"
}

run_stop_hook() {
    local session_id="$1"
    local stop_hook_active="${2:-false}"
    local payload

    payload="$(codex_stop_event "${session_id}" "${stop_hook_active}")"
    run --separate-stderr "${HOOK}" stop codex <<< "${payload}"
}

run_github_body_hook() {
    local command="$1"
    local client="${2:-claude}"
    local payload

    payload="$(jq -cn --arg command "${command}" --arg cwd "${BATS_TEST_TMPDIR}" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_use_id: "test-tool-use", cwd: $cwd, tool_input: {command: $command}}')"
    run --separate-stderr "${HOOK}" pre "${client}" <<< "${payload}"
}

@test "blocks an overlong gh pr create --body before Bash runs" {
    local long_sentence command reason

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    command="gh pr create --body '${long_sentence}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    reason="$(jq -r '.reason' <<< "${output}")"
    [[ "${reason}" == "The edited Markdown contains 1 sentence(s) over the limit."* ]]
    [[ "${reason}" == *"Length: 201 codepoints; limit: 200"* ]]
}

@test "blocks attached -b values containing equals signs like pflag" {
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(199) + "=.")')"

    for command in "gh pr create -b'${long_sentence}'" "gh pr create -b='${long_sentence}'"; do
        run_github_body_hook "${command}"
        [ "${status}" -eq 0 ]
        [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
        [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    done
}

@test "does not treat a title value beginning with a body shorthand as a body" {
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    command="gh pr create -t '-b${long_sentence}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "blocks overlong gh body files through --body-file and -F" {
    local body_file="${BATS_TEST_TMPDIR}/github=body.md"
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${body_file}"

    for option in --body-file -F; do
        command="gh issue comment 42 ${option} '${body_file}'"
        run_github_body_hook "${command}" codex
        [ "${status}" -eq 0 ]
        [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
        [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    done
}

@test "blocks an overlong gh issue comment body passed with attached -F path containing equals" {
    local body_file="${BATS_TEST_TMPDIR}/github=body.md"
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${body_file}"
    command="gh issue comment 42 -F'${body_file}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
}

@test "blocks an overlong gh pr create body passed in a short flag cluster" {
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    command="gh pr create -db'${long_sentence}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
}

@test "fails open for unclassified gh options and options after --" {
    local long_sentence

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    run_github_body_hook "gh pr create --unknown value --body '${long_sentence}'"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run_github_body_hook "gh pr create -- '-b${long_sentence}'"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "fails open for gh issue comment with attached -F- stdin body" {
    run_github_body_hook "gh issue comment 42 -F-"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a passing GitHub body" {
    local sentence command

    sentence="$(node -e 'process.stdout.write("x".repeat(199) + ".")')"
    command="gh pr edit 42 --body '${sentence}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "does not expand a tilde after equals in a GitHub body argument" {
    local home="${BATS_TEST_TMPDIR}/home-directory-that-would-expand" sentence command

    mkdir -p "${home}"
    sentence="~/$(node -e 'process.stdout.write("x".repeat(190) + ".")')"
    [ "${#sentence}" -eq 193 ]
    command="gh pr create --body=${sentence}"

    HOME="${home}" run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a non-gh Bash command unchanged" {
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    command="printf '%s\\n' '${long_sentence}'"

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "fails open when the gh body command needs shell expansion" {
    local body_file="${BATS_TEST_TMPDIR}/github-body.md"
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${body_file}"
    command="gh issue create --body \"\$(cat ${body_file})\""

    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "Claude hook commands fail open when Node.js is unavailable" {
    local empty_bin="${BATS_TEST_TMPDIR}/empty-bin"
    local settings="${BATS_TEST_DIRNAME}/../../../home/private_dot_config/claude/settings.json"
    local hook_command command_count

    mkdir -p "${empty_bin}"
    command_count="$(jq '[.. | objects | .command? // empty | select(contains("markdown-sentence-length"))] | length' "${settings}")"
    [ "${command_count}" -eq 3 ]
    while IFS= read -r hook_command; do
        run /usr/bin/env -i "PATH=${empty_bin}" "HOME=${HOME}" /bin/sh -c "${hook_command}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done < <(jq -r '.. | objects | .command? // empty | select(contains("markdown-sentence-length"))' "${settings}")
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

@test "fails open when textlint reports a contradictory sentence length" {
    local file_path="${BATS_TEST_TMPDIR}/contradictory-report.md"
    local session_id="contradictory-report"
    local fake_bin="${BATS_TEST_TMPDIR}/fake-bin"
    local marker="${BATS_TEST_TMPDIR}/contradictory-npm-called"

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    node -e 'process.stdout.write("x".repeat(200) + ".\n")' > "${file_path}"
    mkdir -p "${fake_bin}"
    cat > "${fake_bin}/npm" << 'EOF'
#!/bin/sh
for arg do
    case "${arg}" in
        *-current.md) current_file="${arg}" ;;
    esac
done
[ -n "${current_file}" ] || exit 2
jq -cn --arg file "${current_file}" '[{filePath: $file, messages: [{ruleId: "sentence-length", message: "sentence length(999)", range: [0, 1], line: 1}]}]' || exit
: > "${CONTRADICTORY_NPM_MARKER}"
EOF
    chmod +x "${fake_bin}/npm"
    export CONTRADICTORY_NPM_MARKER="${marker}"
    PATH="${fake_bin}:${PATH}"
    export PATH

    run_post_hook "${session_id}" "${file_path}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ -e "${marker}" ]
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
