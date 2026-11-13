#!/usr/bin/env bats

setup() {
    export SENTENCE_LENGTH_STATE_DIR="${BATS_TEST_TMPDIR}/sentence-length-state"
    mkdir -p "${SENTENCE_LENGTH_STATE_DIR}"
    HOOK="${BATS_TEST_DIRNAME}/../../../home/private_dot_local/private_bin/exact_common/executable_markdown-sentence-length"
    NEIGHBOR_LENGTH="${BATS_TEST_DIRNAME}/../../../home/private_dot_local/private_bin/exact_common/executable_markdown-neighbor-length"
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

run_github_body_file_hook() {
    local body="$1"
    local client="${2:-claude}"
    local body_file="${BATS_TEST_TMPDIR}/github-body.md"

    printf '%s\n' "${body}" > "${body_file}"
    run_github_body_hook "gh issue create --title t --body-file '${body_file}'" "${client}"
}

assert_github_command_denied() {
    local problem="$1"

    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "$(jq -r '.reason' <<< "${output}")" == *"${problem}"* ]]
    [[ "$(jq -r '.reason' <<< "${output}")" == *"--body-file /absolute/path/body.md"* ]]
}

@test "denies inline GitHub text of any length" {
    local command

    for command in \
        "gh pr create --title t --body 'Short.'" \
        "gh pr create -b'Short.'" \
        "gh pr create -db'Short.'" \
        "gh pr edit 42 --body=Short." \
        "gh pr comment 42 --body 'Short.'" \
        "gh pr review 42 --comment -b 'Short.'" \
        "gh issue comment 42 -b 'Short.'"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it passes inline text with --body or -b"
        run_github_body_hook "${command}" codex
        assert_github_command_denied "it passes inline text with --body or -b"
    done
}

@test "denies GitHub bodies from other sources or without a body file" {
    local command

    for command in "gh pr create --fill" "gh pr create -f" "gh pr create --web" \
        "gh issue create --template bug" "gh issue comment 42 --editor" "gh pr create --recover state.json"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it takes the body from"
    done

    for command in "gh issue comment 42 -F-" "gh pr edit 42 --body-file -"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it reads the body from standard input"
    done

    for command in "gh pr create --title t" "gh issue comment 42" "gh pr create -- '-bShort.'"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it has no --body-file"
    done

    run_github_body_hook "gh pr create --unknown value --body-file body.md"
    assert_github_command_denied "the hook does not recognize the option --unknown"

    for command in "gh pr create --title t --body-file missing.md" "gh pr comment 42 -F /dev/stdin"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "is not a regular file"
    done
}

@test "denies the compound command that published an unchecked PR body" {
    local body_file="${BATS_TEST_TMPDIR}/pr-body.md"
    local item command

    item="$(node -e 'process.stdout.write("- " + ("Long list item sentence. ").repeat(30))')"
    printf '## Changes\n\n%s\n' "${item}" > "${body_file}"
    command="D=${BATS_TEST_TMPDIR}; cd \"${BATS_TEST_TMPDIR}\" && su=\$(gh pr create -R o/r --base main --head x --title \"feat(x): y\" --body-file \"\$D/pr-body.md\") && echo \"\$su\""

    for client in claude codex; do
        run_github_body_hook "${command}" "${client}"
        assert_github_command_denied "its arguments need shell expansion"
    done

    run_github_body_hook "gh pr create -R o/r --head x --title t --body-file '${body_file}'"
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"Fix: split the paragraph or list item."* ]]
}

@test "denies gh calls in aliases, repo flag positions, and shell forms bash runs" {
    local command

    for command in \
        "gh pr new --title t --body 'Short.'" \
        "gh -R o/r pr comment 42 --body 'Short.'" \
        "gh pr --repo=o/r comment 42 --body 'Short.'" \
        "gh -R \"o/r\" pr comment 42 --body 'Short.'" \
        "gh pr --repo='o/r' comment 42 --body 'Short.'" \
        "gh -Ro/r pr comment 42 --body 'Short.'" \
        "echo \$'don\\'t' && gh pr comment 42 --body 'Short.'" \
        "echo \"\$((1<<3))\"
gh pr comment 42 --body 'Short.'" \
        "(( x <<= 2 ))
gh pr comment 42 --body 'Short.'" \
        "cat <<\\EOF
hi
EOF
gh pr comment 42 --body 'Short.'" \
        "jq . <<< \"\$json\"
gh pr comment 42 --body 'Short.'" \
        "n=\$((1<<3))
gh pr comment 42 --body 'Short.'" \
        "# don't forget
gh pr comment 42 --body 'Short.'" \
        "echo \"\`gh pr comment 42 --body 'Short.'\`\"" \
        "cat <<EOF
\$(gh pr comment 42 --body 'Short.')
EOF"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it passes inline text with --body or -b"
    done
}

@test "denies close and reopen comments and allows them without one" {
    local command

    for command in "gh pr close 42 --comment 'Superseded.'" "gh issue close 42 -c 'Done.'" \
        "gh pr close 42 -dc 'Done.'" "gh issue reopen 42 --comment=Again." "gh pr close \"\$n\" --comment x"; do
        run_github_body_hook "${command}"
        assert_github_command_denied "it posts a comment with --comment"
        [[ "$(jq -r '.reason' <<< "${output}")" == *"--body-file /absolute/path/body.md"* ]]
    done

    for command in "gh pr close 42 -d" "gh issue close 42 -r completed" "gh pr close \"\$n\"" "gh pr reopen 42"; do
        run_github_body_hook "${command}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "denies a body file written or named earlier in the same command" {
    local body_file="${BATS_TEST_TMPDIR}/same-command.md"
    local command

    printf 'Old short body.\n' > "${body_file}"
    command="cat > '${body_file}' <<'EOF'
New body.
EOF
gh pr create --title t --body-file '${body_file}'"
    run_github_body_hook "${command}"
    assert_github_command_denied "the command names the body file before gh"

    run_github_body_hook "cd /tmp && gh pr create --title t --body-file same-command.md"
    assert_github_command_denied "the command changes directory, so the --body-file path must be absolute"
}

@test "lints a literal body file inside a compound command" {
    local body_file="${BATS_TEST_TMPDIR}/compound.md"
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${body_file}"
    command="git push -u origin x && gh pr create -R o/r --head x --title \"feat(x): y\" \\
    --body-file '${body_file}' 2>&1 | tail -1"

    for client in claude codex; do
        run_github_body_hook "${command}" "${client}"
        [ "${status}" -eq 0 ]
        [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
        [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    done

    printf 'Short body.\n' > "${body_file}"
    run_github_body_hook "${command}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "blocks overlong gh body files through --body-file and -F forms" {
    local body_file="${BATS_TEST_TMPDIR}/github=body.md"
    local long_sentence command

    long_sentence="$(node -e 'process.stdout.write("x".repeat(200) + ".")')"
    printf '%s\n' "${long_sentence}" > "${body_file}"

    for command in "gh issue comment 42 --body-file '${body_file}'" "gh issue comment 42 -F '${body_file}'" \
        "gh issue comment 42 -F'${body_file}'" "gh pr review 42 --request-changes -F '${body_file}'"; do
        run_github_body_hook "${command}" codex
        [ "${status}" -eq 0 ]
        [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
        [[ "${output}" == *"Length: 201 codepoints; limit: 200"* ]]
    done
}

@test "allows gh commands that post no text or only mention gh in prose" {
    local body_file="${BATS_TEST_TMPDIR}/short.md"
    local command

    printf 'Short body.\n' > "${body_file}"

    for command in \
        "gh pr edit 42 --add-label rebase >/dev/null" \
        "gh pr review 42 --approve" \
        "gh issue comment 42 --delete-last --yes" \
        "gh pr edit --help | head -5" \
        "gh pr create --help=true --body 'Short.'" \
        "gh pr create -t '-bShort.' --body-file '${body_file}'" \
        "gh issue comment 42 --attach shot.png" \
        "gh pr create --title t --body-file '${body_file}' # it's linted" \
        "git commit -m 'fix: gh pr create --body parsing'" \
        "herdr agent send w 'Open it with \`gh pr create --body-file <draft>\`.'" \
        "# gh pr create --body 'Short.'" \
        "cat > notes.txt <<'EOF'
gh pr create --body 'Short.'
EOF"; do
        run_github_body_hook "${command}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done

    run_github_body_hook "gh pr create --help=false --body 'Short.'"
    assert_github_command_denied "it passes inline text with --body or -b"
}

@test "allows a passing GitHub body file" {
    run_github_body_file_hook "$(node -e 'process.stdout.write("x".repeat(199) + ".")')"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "blocks a GitHub prose paragraph over 600 codepoints" {
    local paragraph reason prefix

    paragraph="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(6) + "😀")')"

    run_github_body_file_hook "${paragraph}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    reason="$(jq -r '.reason' <<< "${output}")"
    prefix="$(printf '%s' "${paragraph}" | cut -c1-20)"
    [[ "${reason}" == *"Paragraph/list item: ${prefix}"* ]]
    [[ "${reason}" == *"Length: 601 codepoints; limit: 600"* ]]
    [[ "${reason}" == *"Fix: split the paragraph or list item."* ]]
}

@test "allows a long GitHub list item when URLs and inline code make it long" {
    local prose inline_code item

    prose="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(5) + "p".repeat(89) + ".")')"
    inline_code="$(node -e 'process.stdout.write(String.fromCharCode(96) + "c".repeat(20) + String.fromCharCode(96))')"

    for item in "- ${prose} https://example.com/a-long-url" "- ${prose} ${inline_code}"; do
        run_github_body_file_hook "${item}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "excludes fenced code from GitHub paragraph length" {
    local prose code

    prose="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(5) + "p".repeat(89) + ".")')"
    code="$(node -e 'process.stdout.write("c".repeat(50))')"

    run_github_body_file_hook "${prose}
\`\`\`text
${code}
\`\`\`"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows long HTML and Markdown tables in GitHub bodies" {
    local cell rows

    cell="$(node -e 'process.stdout.write("t".repeat(140) + ".")')"
    run_github_body_file_hook "<table><tr><td>${cell}</td><td>${cell}</td><td>${cell}</td><td>${cell}</td><td>${cell}</td></tr></table>"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    rows="$(for _ in 1 2 3 4 5; do printf '| %s |\n' "${cell}"; done)"
    run_github_body_file_hook "| value |
| --- |
${rows}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a GitHub prose paragraph of 599 codepoints" {
    run_github_body_file_hook "$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(5) + "p".repeat(99))')"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a 301-codepoint paragraph after a 301-codepoint heading" {
    local heading paragraph

    heading="$(node -e 'process.stdout.write(("h".repeat(98) + ". ").repeat(3) + "h")')"
    paragraph="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(3) + "p")')"

    run_github_body_file_hook "# ${heading}
${paragraph}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "allows a long GitHub HTML comment" {
    run_github_body_file_hook "<!-- $(node -e 'process.stdout.write("c".repeat(700))') -->"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "counts a lazy continuation as part of its GitHub list item" {
    local first continuation

    first="$(node -e 'process.stdout.write(("l".repeat(98) + ". ").repeat(3) + "l")')"
    continuation="$(node -e 'process.stdout.write(("c".repeat(98) + ". ").repeat(3) + "c")')"

    run_github_body_file_hook "- ${first}
${continuation}"
    [ "${status}" -eq 0 ]
    [ "$(jq -r '.decision' <<< "${output}")" = "block" ]
    [[ "${output}" == *"Length: 603 codepoints; limit: 600"* ]]
    [[ "${output}" == *"Fix: split the paragraph or list item."* ]]
}

@test "does not merge a paragraph after a GitHub list item ending in fenced code" {
    local first paragraph fence

    first="$(node -e 'process.stdout.write(("l".repeat(98) + ". ").repeat(3) + "l")')"
    paragraph="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(3) + "p")')"
    fence="$(printf '\140\140\140')"

    run_github_body_file_hook "- ${first}
  ${fence}text
  code
  ${fence}
${paragraph}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

@test "does not apply the GitHub paragraph limit to Markdown edits" {
    local file_path="${BATS_TEST_TMPDIR}/long-markdown-paragraph.md"
    local session_id="long-markdown-paragraph"
    local paragraph

    printf 'Short sentence.\n' > "${file_path}"
    capture_baseline "${session_id}" "${file_path}"
    paragraph="$(node -e 'process.stdout.write(("p".repeat(98) + ". ").repeat(6) + "😀")')"
    printf '%s\n' "${paragraph}" > "${file_path}"

    run_post_hook "${session_id}" "${file_path}"
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

@test "blocks long numbered prose beside short neighboring bullets" {
    local file_path="${BATS_TEST_TMPDIR}/neighbor-length.md"
    cat > "${file_path}" << 'EOF'
## Surrounding style
- Keep this brief.
- Use short bullets.
- State one point.
- Keep it readable.

## Changed section
1. This newly edited sentence is a deliberately long numbered paragraph that continues far beyond the short surrounding bullet style and should exceed the median of the neighboring bullet lengths.
2. This second numbered paragraph is also intentionally much longer than the surrounding bullets and should be named in the failure output.
EOF

    run "${NEIGHBOR_LENGTH}" "${file_path}" --heading "Changed section"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Form differs: neighbors are mostly bullets; section \"Changed section\""* ]]
    [[ "${output}" == *"Sentence in section \"Changed section\""* ]]
    [[ "${output}" == *"neighbor median limit:"* ]]
    [[ "${output}" == *"This second numbered paragraph"* ]]
}

@test "help explains predominant form matching and report shares" {
    run "${NEIGHBOR_LENGTH}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Form compares the predominant line kind; structure fails above neighbors' median + 2 bullets or above 4 when neighbors nest."* ]]
    [[ "${output}" == *"Flat edited bullets fail when neighbors nest; --report shows shares and hierarchy measurements."* ]]
}

@test "reports codepoint lengths and skips fenced code and tables for an edited file" {
    local document="${BATS_TEST_TMPDIR}/neighbor-report.md"
    local edited="${BATS_TEST_TMPDIR}/edited-part.md"
    local long

    long="$(node -e 'process.stdout.write("x".repeat(250))')"
    {
        printf '%s\n' '- あ。' '- い。' '- う.'
        printf '\n```text\n%s\n```\n\n' "${long}"
        printf '%s\n' '| value |' '| --- |' "| ${long} |"
    } > "${document}"
    printf '%s\n' '- 😀。' > "${edited}"

    run "${NEIGHBOR_LENGTH}" "${document}" --edited-file "${edited}" --report
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Sentences/bullets: 3 (0 sentences, 3 bullets); median 2 chars; max 2 chars"* ]]
    [[ "${output}" == *"Sentences/bullets: 1 (0 sentences, 1 bullets); median 2 chars; max 2 chars"* ]]
}

@test "reports form shares and nesting for a heading with inline code and HTML" {
    local file_path="${BATS_TEST_TMPDIR}/neighbor-form.md"
    cat > "${file_path}" << 'EOF'
## Neighbors
Lead.
- One.
- Two.
  - Nested.
1. Step.

## Changed `part` <span>section</span>
Edit.
- A.
  - B.
1. C.
EOF

    run "${NEIGHBOR_LENGTH}" "${file_path}" --heading "Changed part section" --report
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Form: mostly bullets (bullets 3/5 (60.0%), prose 1/5 (20.0%), numbered steps 1/5 (20.0%))"* ]]
    [[ "${output}" == *"Nesting depth: median 1, max 2"* ]]
    [[ "${output}" == *"Form: mostly bullets (bullets 2/4 (50.0%), prose 1/4 (25.0%), numbered steps 1/4 (25.0%))"* ]]
    [[ "${output}" == *"Bullet hierarchy: 3 bullets; 1 with children (33.3%); max depth 2"* ]]
    [[ "${output}" == *"Top-level bullets per section: \"Neighbors\" at line 1: 2; median 2"* ]]
}

@test "names every edited bullet longer than the neighboring median" {
    local document="${BATS_TEST_TMPDIR}/neighbor-bullets.md"
    local edited="${BATS_TEST_TMPDIR}/edited-bullets.md"

    printf '%s\n' '- One.' '- Two.' '- Three.' > "${document}"
    printf '%s\n' '- This edited bullet is much longer than each neighboring bullet.' '- This second edited bullet is also longer than the neighboring median.' > "${edited}"

    run "${NEIGHBOR_LENGTH}" "${document}" --edited-file "${edited}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Bullet in edited file edited-bullets.md at line 1"* ]]
    [[ "${output}" == *"Bullet in edited file edited-bullets.md at line 2"* ]]
    [[ "${output}" == *"neighbor median limit:"* ]]
}

@test "rejects seven flat bullets beside nested neighbors" {
    local file_path="${BATS_TEST_TMPDIR}/neighbor-hierarchy.md"
    cat > "${file_path}" << 'EOF'
## Neighbor style
- Parent one.
  - Child one.
  - Child two.
- Parent two.
  - Child three.
  - Child four.

## Changed section
- A.
- B.
- C.
- D.
- E.
- F.
- G.
EOF

    run "${NEIGHBOR_LENGTH}" "${file_path}" --heading "Changed section" --report
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Bullet hierarchy: 6 bullets; 2 with children (33.3%); max depth 2"* ]]
    [[ "${output}" == *"Top-level bullets per section:"*"\"Neighbor style\""*"median 2"* ]]
    [[ "${output}" == *"Bullet hierarchy differs: section \"Changed section\""*"is flat (max depth 1); neighbors nest"* ]]
    [[ "${output}" == *"Top-level bullet siblings in section \"Changed section\""*"7; limit: 4"*"neighbors' median: 2"* ]]
}
