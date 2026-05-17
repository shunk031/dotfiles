#!/usr/bin/env bats

readonly CODEX_WORKLOG_AGENT_PATH="./home/dot_config/codex/agents/worklog-manager.toml"
readonly CODEX_WORKLOG_SKILL_PATH="./home/dot_config/exact_agents/skills/worklog-manager/SKILL.md"
readonly STARTUP_CONFLICT_FIXTURE="./tests/install/common/fixtures/worklog_manager_conflict_contract/startup_conflict_prompt.txt"
readonly CONFIRMED_OVERRIDE_FIXTURE="./tests/install/common/fixtures/worklog_manager_conflict_contract/confirmed_override_prompt.txt"

function combined_worklog_contract_text() {
    printf '%s\n%s\n' "$(< "${CODEX_WORKLOG_SKILL_PATH}")" "$(< "${CODEX_WORKLOG_AGENT_PATH}")"
}

function assert_fixture_group_present() {
    local fixture="$1"
    local group_name="$2"
    local haystack="$3"
    local entry=""
    local group=""
    local found=0
    local token=""

    while IFS= read -r entry; do
        [ -n "${entry}" ] || continue
        group="${entry%%::*}"
        token="${entry#*::}"
        [ "${group}" = "${group_name}" ] || continue
        found=1

        if [[ "${haystack}" != *"${token}"* ]]; then
            echo "missing ${group_name} token: ${token}"
            return 1
        fi
    done < "${fixture}"

    [ "${found}" -eq 1 ]
}

@test "[common] worklog conflict report contract defers writes until confirmation" {
    local combined_text
    combined_text="$(combined_worklog_contract_text)"

    assert_fixture_group_present "${STARTUP_CONFLICT_FIXTURE}" "conflict-report" "${combined_text}"
}

@test "[common] confirmed override contract rewrites plan and todo session-locally" {
    local combined_text
    combined_text="$(combined_worklog_contract_text)"

    assert_fixture_group_present "${CONFIRMED_OVERRIDE_FIXTURE}" "confirmed-override" "${combined_text}"
}

@test "[common] rejection and clarification leave plan and todo unchanged" {
    local combined_text
    combined_text="$(combined_worklog_contract_text)"

    assert_fixture_group_present "${STARTUP_CONFLICT_FIXTURE}" "clarification-rejection" "${combined_text}"
}
