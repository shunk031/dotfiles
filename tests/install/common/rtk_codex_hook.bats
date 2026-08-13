#!/usr/bin/env bats

readonly HOOKS_PATH="./home/dot_codex/hooks.json"
readonly SCRIPT_PATH="./home/dot_codex/hooks/rtk-rewrite.sh"

@test "[common] Codex registers the RTK PreToolUse hook" {
    [ -x "${SCRIPT_PATH}" ]
    run jq -e '
        (.hooks.PreToolUse | length == 1)
        and .hooks.PreToolUse[0].matcher == "^Bash$"
        and .hooks.PreToolUse[0].hooks[0].type == "command"
        and .hooks.PreToolUse[0].hooks[0].command == "~/.codex/hooks/rtk-rewrite.sh"
    ' "${HOOKS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Codex RTK hook adapter returns updatedInput" {
    run grep -F 'tool_input.command' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'rtk rewrite' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'updatedInput: {command: $command}' "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] Codex RTK hook rewrites supported Bash commands" {
    local bin_path="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "${bin_path}"
    cat > "${bin_path}/rtk" << 'EOF'
#!/usr/bin/env bash

if [ "$1" = "rewrite" ] && [ "$2" = "git status" ]; then
    printf '%s' 'rtk git status'
    exit 3
fi

exit 1
EOF
    chmod +x "${bin_path}/rtk"

    run env PATH="${bin_path}:${PATH}" HOME="${BATS_TEST_TMPDIR}/home" bash "${SCRIPT_PATH}" << 'EOF'
{"tool_name":"Bash","tool_input":{"command":"git status"}}
EOF
    [ "${status}" -eq 0 ]
    run jq -e '.hookSpecificOutput.permissionDecision == "allow" and .hookSpecificOutput.updatedInput.command == "rtk git status"' <<< "${output}"
    [ "${status}" -eq 0 ]
}

@test "[common] Codex RTK hook ignores unsupported commands and tools" {
    local bin_path="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "${bin_path}"
    cat > "${bin_path}/rtk" << 'EOF'
#!/usr/bin/env bash
exit 1
EOF
    chmod +x "${bin_path}/rtk"

    run env PATH="${bin_path}:${PATH}" HOME="${BATS_TEST_TMPDIR}/home" bash "${SCRIPT_PATH}" << 'EOF'
{"tool_name":"Bash","tool_input":{"command":"echo hello"}}
EOF
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run env PATH="${bin_path}:${PATH}" HOME="${BATS_TEST_TMPDIR}/home" bash "${SCRIPT_PATH}" << 'EOF'
{"tool_name":"Read","tool_input":{"command":"git status"}}
EOF
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
