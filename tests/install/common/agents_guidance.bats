#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly CODEX_AGENTS_TEMPLATE_PATH="./home/dot_config/codex/AGENTS.md.tmpl"
readonly CODEX_AGENTS_SPECIFIC_PATH="./home/dot_config/codex/AGENTS.codex.md"
readonly CODEX_AGENTS_ADAPTER_TEMPLATE_PATH="./home/dot_codex/AGENTS.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_WORKLOG_AGENT_PATH="./home/dot_config/codex/agents/worklog-manager.toml"
readonly CODEX_WORKLOG_SKILL_PATH="./home/dot_config/exact_agents/skills/worklog-manager/SKILL.md"
readonly CODEX_WORKLOG_SKILL_OPENAI_PATH="./home/dot_config/exact_agents/skills/worklog-manager/agents/openai.yaml"
readonly CODEX_WORKLOG_RULES_PATH="./home/dot_config/exact_agents/skills/worklog-manager/references/learn_rules.md"
readonly CODEX_WORKLOG_AUDIT_SCRIPT_PATH="./home/dot_config/exact_agents/skills/worklog-manager/scripts/codex_worklog_audit.py"
readonly CODEX_GH_AGENT_PATH="./home/dot_config/codex/agents/gh-workflow-manager.toml"
readonly LEGACY_GH_FIRST_SKILL_PATH="./home/dot_config/exact_agents/skills/gh-first-workflow"
readonly AGENTS_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_AGENTS.md.tmpl"
readonly CLAUDE_MD_PATH="./home/dot_config/claude/CLAUDE.md"
readonly CLAUDE_SYMLINK_TEMPLATE="./home/dot_claude/symlink_CLAUDE.md.tmpl"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly AGENTS_README_PATH="./home/exact_dot_agents/README.md"
readonly CLAUDE_README_PATH="./home/dot_claude/README.md"
readonly CODEX_README_PATH="./home/dot_codex/README.md"
readonly CANONICAL_AGENTS_README_PATH="./home/dot_config/exact_agents/README.md"
readonly CANONICAL_CLAUDE_README_PATH="./home/dot_config/claude/README.md"
readonly CANONICAL_CODEX_README_PATH="./home/dot_config/codex/README.md"

@test "[common] codex guidance renders the shared and Codex-only guidance together" {
    [ -f "${SHARED_AGENTS_PATH}" ]
    [ -f "${CODEX_AGENTS_TEMPLATE_PATH}" ]
    [ -f "${CODEX_AGENTS_SPECIFIC_PATH}" ]
    [ -f "${CODEX_AGENTS_ADAPTER_TEMPLATE_PATH}" ]

    local shared_contents
    local codex_specific_contents
    local rendered_codex

    run grep -F 'include "dot_config/exact_agents/AGENTS.md"' "${CODEX_AGENTS_TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'include "dot_config/codex/AGENTS.codex.md"' "${CODEX_AGENTS_TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'includeTemplate "dot_config/codex/AGENTS.md.tmpl" .' "${CODEX_AGENTS_ADAPTER_TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]

    shared_contents="$(< "${SHARED_AGENTS_PATH}")"
    codex_specific_contents="$(< "${CODEX_AGENTS_SPECIFIC_PATH}")"
    rendered_codex="$(printf '%s\n\n%s' "${shared_contents}" "${codex_specific_contents}")"

    [[ "${rendered_codex}" == "${shared_contents}"$'\n\n''## Codex Only'* ]]
}

@test "[common] codex guidance defines 3-minute polling for gh and worklog subagents" {
    local shared_contents
    local codex_specific_contents
    local rendered_codex_path

    rendered_codex_path="${BATS_TEST_TMPDIR}/codex-agents.md"
    shared_contents="$(< "${SHARED_AGENTS_PATH}")"
    codex_specific_contents="$(< "${CODEX_AGENTS_SPECIFIC_PATH}")"
    printf '%s\n\n%s' "${shared_contents}" "${codex_specific_contents}" > "${rendered_codex_path}"

    run grep -F '`gh_workflow_manager` と `worklog_manager` では 180 秒を超えて待たず' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`wait_agent(timeout_ms=180000)`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '同じ subagent スレッドへ `send_input` で追加の状態確認を送り' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`現在の段階`、`次の段階`、`ブロッカーの有無`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`interrupt=true` は明らかな停止や即時の方針変更が必要な場合だけ使ってください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`wait_agent(timeout_ms=180000)`' "${rendered_codex_path}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared and Claude entrypoints define acknowledgment messages" {
    run grep -F '🤖 I read ~/.agents/AGENTS.md.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '🤖 I read ~/.claude/CLAUDE.md.' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/AGENTS.md" ]
    [ -f "${CODEX_AGENTS_ADAPTER_TEMPLATE_PATH}" ]
    [ "$(< "${CODEX_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/agents" ]
    run grep -F "@~/.agents/AGENTS.md" "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '一旦 `~/.agents/AGENTS.md` を読んでください。' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(< "${CLAUDE_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/CLAUDE.md" ]
}

@test "[common] codex worklog is delegated to the custom subagent" {
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]

    run grep -F 'name = "worklog_manager"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '~/.agents/skills/worklog-manager/SKILL.md' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'source of truth for startup learn selection, plan/todo/learn metadata, stale-learn hard gating, and audit behavior' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "startup audit is mandatory" "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Do not continue startup with best-effort learn selection." "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`Active learnings`, `Needs revalidation`, `Ignored historical entries`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Required `learn` keys:' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'Keep `todo.status` within' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F "worklog_manager" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '$(date +%Y%m%d_%H%M%S)_plan.md' "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "#### plan/todo/learn の frontmatter ルール" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] worklog skill defines stale-learn hard gating and audit resources" {
    [ -f "${CODEX_WORKLOG_SKILL_PATH}" ]
    [ -f "${CODEX_WORKLOG_SKILL_OPENAI_PATH}" ]
    [ -f "${CODEX_WORKLOG_RULES_PATH}" ]
    [ -f "${CODEX_WORKLOG_AUDIT_SCRIPT_PATH}" ]

    run grep -F 'name: worklog-manager' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Treat `## Active` as the only startup source of truth.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'If `learn_index.md` exists, run `python3 ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py check` before reading any learn entry.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'If `check` fails, stop startup and report the exact audit failures to the parent. Do not continue with best-effort learn selection.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Treat `## Needs Review` as context candidates, not facts.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Ignore `## Superseded` and `## Archived` unless the parent explicitly asks for history or migration context.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`Active learnings`' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`Needs revalidation`' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`Ignored historical entries`' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`status` must be one of `active | needs_review | superseded | archived`.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`freshness: drift_prone` requires `review_after`.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`status: superseded` requires `superseded_by`.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Replacement learn files should declare `supersedes`.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Do not promote session-local facts, current branch names, current paths, default-branch names' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`default branch is master` must not stay `active`' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'startup must run `scripts/codex_worklog_audit.py check` before reading any learn entry' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'stop startup and return the exact audit failures to the parent instead of falling back to best-effort learn selection' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`origin/master`' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'default_prompt: "Use $worklog-manager to manage Codex worklog files and audit stale learn metadata."' "${CODEX_WORKLOG_SKILL_OPENAI_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex GitHub workflow is delegated to the custom subagent" {
    [ -f "${CODEX_GH_AGENT_PATH}" ]
    [ ! -e "${LEGACY_GH_FIRST_SKILL_PATH}" ]

    run grep -F 'name = "gh_workflow_manager"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "gh_workflow_manager" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "gh-first-workflow" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "gh pr create" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "git rev-parse --show-toplevel" "${CODEX_AGENTS_SPECIFIC_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] layout readmes describe the adapter and canonical layout" {
    [ -f "${AGENTS_README_PATH}" ]
    [ -f "${CLAUDE_README_PATH}" ]
    [ -f "${CODEX_README_PATH}" ]
    [ -f "${CANONICAL_AGENTS_README_PATH}" ]
    [ -f "${CANONICAL_CLAUDE_README_PATH}" ]
    [ -f "${CANONICAL_CODEX_README_PATH}" ]

    run grep -F "~/.agents" "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/exact_agents/" "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.claude" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/claude/" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.md.tmpl" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/exact_agents/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/codex/AGENTS.codex.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/codex/agents/" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.agents" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../exact_dot_agents/" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/AGENTS.md" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "@~/.agents/AGENTS.md" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.claude" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_claude/" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "@~/.agents/AGENTS.md" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.codex.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "(agents/)" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_codex/AGENTS.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] layout readmes stay repo-only" {
    [ -f "${CHEZMOIIGNORE_PATH}" ]

    run grep -Fx ".agents/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".claude/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".codex/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".config/agents/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}
