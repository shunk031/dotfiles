#!/usr/bin/env bash

# @file home/dot_codex/hooks/rtk-rewrite.sh
# @brief Rewrite Codex Bash tool calls through `rtk`.
# @description
#   Reads a Codex `PreToolUse` event from stdin and returns an updated command
#   only when the pinned RTK binary can rewrite the original command.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly MISE_CONFIG_PATH="${HOME}/.config/mise/config.toml"

#
# @description Rewrite a raw shell command with the available RTK installation.
# @arg $1 command Raw shell command from Codex's Bash tool input.
# @stdout The rewritten command when RTK recognizes it.
# @exitcode 0 When the command was rewritten.
# @exitcode 1 When RTK is unavailable or has no rewrite for the command.
#
function rewrite_with_rtk() {
    local command="$1" rewritten="" status=0

    if command -v rtk > /dev/null 2>&1; then
        rewritten="$(rtk rewrite "${command}")" || status=$?
    elif [ -x "${MISE_BIN}" ]; then
        if [ -r "${MISE_CONFIG_PATH}" ]; then
            rewritten="$(MISE_CONFIG_FILE="${MISE_CONFIG_PATH}" "${MISE_BIN}" exec -- rtk rewrite "${command}")" || status=$?
        else
            rewritten="$("${MISE_BIN}" exec -- rtk rewrite "${command}")" || status=$?
        fi
    else
        return 1
    fi

    if { [ "${status}" -eq 0 ] || [ "${status}" -eq 3 ]; } && [ -n "${rewritten}" ]; then
        printf '%s\n' "${rewritten}"
        return 0
    fi
    return "${status}"
}

#
# @description Emit Codex's `updatedInput` response for a rewritten command.
# @arg $1 command Rewritten shell command.
#
function emit_rewrite() {
    local command="$1"

    jq -n --arg command "${command}" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow",
            updatedInput: {command: $command}
        }
    }'
}

#
# @description Read a Codex hook event and rewrite supported Bash commands.
#
function main() {
    local input tool_name raw_command rewritten

    command -v jq > /dev/null 2>&1 || return 0
    input="$(cat)"
    tool_name="$(jq -r '.tool_name // empty' <<< "${input}")" || return 0
    [ "${tool_name}" = "Bash" ] || return 0

    raw_command="$(jq -r '.tool_input.command // empty' <<< "${input}")" || return 0
    [ -n "${raw_command}" ] || return 0

    if ! rewritten="$(rewrite_with_rtk "${raw_command}")"; then
        return 0
    fi
    [ -n "${rewritten}" ] || return 0
    [ "${rewritten}" != "${raw_command}" ] || return 0

    emit_rewrite "${rewritten}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
