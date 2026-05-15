#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_WORKLOG_AGENT_PATH="./home/dot_config/codex/agents/worklog-manager.toml"
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

@test "[common] codex guidance starts with the shared agent guidance" {
    [ -f "${SHARED_AGENTS_PATH}" ]
    [ -f "${CODEX_AGENTS_PATH}" ]

    local shared_bytes
    local shared_lines
    local shared_contents
    local codex_prefix

    shared_bytes="$(wc -c < "${SHARED_AGENTS_PATH}" | tr -d '[:space:]')"
    shared_lines="$(wc -l < "${SHARED_AGENTS_PATH}" | tr -d '[:space:]')"
    shared_contents="$(< "${SHARED_AGENTS_PATH}")"
    codex_prefix="$(head -c "${shared_bytes}" "${CODEX_AGENTS_PATH}")"

    [ "${codex_prefix}" = "${shared_contents}" ]

    [ "$(sed -n "$((shared_lines + 2))p" "${CODEX_AGENTS_PATH}")" = "## Codex Only" ]
}

@test "[common] codex guidance defines 3-minute polling for gh and worklog subagents" {
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

    run grep -F '`wait_agent(timeout_ms=180000)`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/AGENTS.md" ]
    [ "$(< "${CODEX_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/AGENTS.md" ]
    [ "$(< "${CODEX_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/agents" ]
    [ "$(< "${CLAUDE_MD_PATH}")" = "@~/.agents/AGENTS.md" ]
    [ "$(< "${CLAUDE_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/CLAUDE.md" ]
}

@test "[common] codex worklog is delegated to the custom subagent" {
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]

    run grep -F 'name = "worklog_manager"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "worklog_manager" "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '$(date +%Y%m%d_%H%M%S)_plan.md' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "#### plan/todo/learn の frontmatter ルール" "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] codex worklog manager hard-gates startup learns" {
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]

    run grep -F 'treat only the `## Active` section as the startup source of truth' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`## Needs Review` may be consulted as reference but never as validated fact during startup' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Do not read `## Superseded` or `## Archived` unless the parent explicitly asks for historical context' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Reply to the parent with exactly three short sections in this order: `Active learnings`, `Needs revalidation`, `Ignored historical entries`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex worklog manager defines the learn freshness metadata rules" {
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]

    run grep -F 'Required `learn` keys: `validated`, `apply_to`, `status`, `freshness`, `last_validated_at`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`freshness: drift_prone` requires `review_after`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`status: superseded` requires `superseded_by`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Replacement learn files should record the prior file in `supersedes`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Do not promote session-limited facts, current branch/path/default branch, or state that can be rechecked immediately into learn files' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`- [タイトル](ファイル名) [stable|drift_prone] — 要約（150 文字以内）`' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex GitHub workflow is delegated to the custom subagent" {
    [ -f "${CODEX_GH_AGENT_PATH}" ]
    [ ! -e "${LEGACY_GH_FIRST_SKILL_PATH}" ]

    run grep -F 'name = "gh_workflow_manager"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "gh_workflow_manager" "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "gh-first-workflow" "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "gh pr create" "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "git rev-parse --show-toplevel" "${CODEX_AGENTS_PATH}"
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
    run grep -F "../dot_config/codex/AGENTS.md" "${CODEX_README_PATH}"
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
    run grep -F "keeps the home path stable" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.claude" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_claude/" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "(AGENTS.md)" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "(agents/)" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_codex/" "${CANONICAL_CODEX_README_PATH}"
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
