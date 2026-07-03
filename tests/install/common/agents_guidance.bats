#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_CODEX_ONLY_PATH="./home/dot_config/codex/AGENTS.codex-only.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly CODEX_CODEX_ONLY_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.codex-only.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_WORKLOG_AGENT_PATH="./home/dot_config/codex/agents/worklog-manager.toml"
readonly SHARED_WORKLOG_AGENT_PATH="./home/dot_config/exact_agents/agents/worklog-manager.md"
readonly CODEX_WORKLOG_SKILL_PATH="./home/dot_config/exact_agents/skills/worklog-manager/SKILL.md"
readonly CODEX_WORKLOG_SKILL_OPENAI_PATH="./home/dot_config/exact_agents/skills/worklog-manager/agents/openai.yaml"
readonly CODEX_WORKLOG_RULES_PATH="./home/dot_config/exact_agents/skills/worklog-manager/references/learn_rules.md"
readonly CODEX_WORKLOG_AUDIT_SCRIPT_PATH="./home/dot_config/exact_agents/skills/worklog-manager/scripts/codex_worklog_audit.py"
readonly CODEX_GH_AGENT_PATH="./home/dot_config/codex/agents/gh-workflow-manager.toml"
readonly SHARED_GH_AGENT_PATH="./home/dot_config/exact_agents/agents/gh-workflow-manager.md"
readonly LEGACY_GH_FIRST_SKILL_PATH="./home/dot_config/exact_agents/skills/gh-first-workflow"
readonly AGENTS_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_AGENTS.md.tmpl"
readonly SHARED_AGENT_DIR_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_agents.tmpl"
readonly CLAUDE_MD_PATH="./home/dot_config/claude/CLAUDE.md"
readonly CLAUDE_SYMLINK_TEMPLATE="./home/dot_claude/symlink_CLAUDE.md.tmpl"
readonly CLAUDE_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_claude/symlink_agents.tmpl"
readonly CLAUDE_GH_AGENT_PATH="./home/dot_config/claude/agents/gh-workflow-manager.md"
readonly CLAUDE_WORKLOG_AGENT_PATH="./home/dot_config/claude/agents/worklog-manager.md"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly AGENTS_README_PATH="./home/exact_dot_agents/README.md"
readonly CLAUDE_README_PATH="./home/dot_claude/README.md"
readonly CODEX_README_PATH="./home/dot_codex/README.md"
readonly CANONICAL_AGENTS_README_PATH="./home/dot_config/exact_agents/README.md"
readonly CANONICAL_CLAUDE_README_PATH="./home/dot_config/claude/README.md"
readonly CANONICAL_CODEX_README_PATH="./home/dot_config/codex/README.md"

@test "[common] codex guidance entrypoint reads shared and codex-only guidance" {
    [ -f "${SHARED_AGENTS_PATH}" ]
    [ -f "${CODEX_AGENTS_PATH}" ]
    [ -f "${CODEX_CODEX_ONLY_PATH}" ]
    [ ! -e "./home/dot_config/codex/AGENTS.override.md" ]
    [ ! -e "./home/dot_codex/symlink_AGENTS.override.md.tmpl" ]
    [ ! -e "./home/dot_config/codex/AGENTS.md.tmpl" ]
    [ ! -e "./home/dot_codex/AGENTS.md.tmpl" ]

    run grep -F '> [!NOTE]' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F -- '- まず `~/.agents/AGENTS.md` を読んでください。' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F -- '- そのうえで、この `~/.codex/AGENTS.md` に書かれている内容も適用してください。' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '## Codex Only' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F -- '- Codex only の追加の指示として `~/.codex/AGENTS.codex-only.md` を読んでください。' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> [!NOTE]' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> After reading this `AGENTS.codex-only.md`, say: `🤖 I read ~/.codex/AGENTS.codex-only.md.`' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.codex/AGENTS.md` から追加で読む Codex 固有の設定です。' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex guidance defines 3-minute polling for gh and worklog subagents" {
    run grep -F '`gh-workflow-manager` と `worklog-manager` では 180 秒を超えて待たず' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`wait_agent(timeout_ms=180000)`' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '同じ subagent スレッドへ `send_input` で追加の状態確認を送り' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`現在の段階`、`次の段階`、`ブロッカーの有無`' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'PR URL を受け取った時点で完了扱いにしてはいけません' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'required checks の結果が確定してからユーザへ最終報告してください' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`interrupt=true` は明らかな停止や即時の方針変更が必要な場合だけ使ってください' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance requires concrete coding plans" {
    run grep -F '## Plan の具体性' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '変更対象のディレクトリ・ファイルパス' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '追加・編集・削除する関数、クラス、設定キー、CLI 引数、公開 API' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '各ファイルで何をどう変えるか' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '確認する assertion の要点' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '関数シグネチャ案、疑似コード、または短いコードスニペットを必ず含めてください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '実装判断が増える plan では' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`どのファイルのどのシンボルをどう変えるか` が伝わる粒度で書いてください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '未完成の plan を最終 plan として提示してはいけません' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '「Assumptions」または「前提」として明示し' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex-only guidance keeps the proposed_plan gate and defers to shared plan rules" {
    run grep -F '### Plan の具体性 (Codex 固有)' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'plan の具体性の共通ルールは `~/.agents/AGENTS.md` の「Plan の具体性」を適用してください' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '未完成の状態で `<proposed_plan>` を出してはいけません' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '変更対象のディレクトリ・ファイルパス' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared guidance protects uncommitted diffs" {
    run grep -F '## 未コミット差分の保護' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '自分が作ったと明確に証明できない差分を、明示的な許可なしに戻してはいけません' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '差分を戻すのではなく、stage 対象を限定する、別 worktree を使う、またはユーザーへ確認してください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '## 未コミット差分の保護' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared, Claude, and Codex entrypoints define acknowledgment note blocks" {
    run grep -F '> [!NOTE]' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> After reading this `AGENTS.md`, say: `🤖 I read ~/.agents/AGENTS.md.`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '> [!NOTE]' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> After reading this `CLAUDE.md`, say: `🤖 I read ~/.claude/CLAUDE.md.`' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '> [!NOTE]' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance defines shared agent wrapper policy" {
    run grep -F '## エージェント設定' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '複数ツールで使う subagent / custom agent の長い共通指示は `~/.agents/agents/<name>.md` を source of truth にしてください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Claude Code 用の `~/.claude/agents/<name>.md` は YAML frontmatter を保持し、本文では `~/.agents/agents/<name>.md` を最初に読むよう明示してください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Codex 用の `~/.codex/agents/<name>.toml` は Codex 固有設定を保持し、`developer_instructions` では `~/.agents/agents/<name>.md` を最初に読むよう明示してください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '同じ長文指示を Claude / Codex の wrapper にコピーしないでください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Markdown を Python などでパースして TOML / Markdown を生成する仕組みは、明示的に必要になるまで追加しないでください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/AGENTS.md" ]
    [ "$(< "${SHARED_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/agents" ]
    [ "$(< "${CODEX_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/AGENTS.md" ]
    [ "$(< "${CODEX_CODEX_ONLY_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/AGENTS.codex-only.md" ]
    [ ! -e "./home/dot_codex/symlink_AGENTS.override.md.tmpl" ]
    [ "$(< "${CODEX_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/agents" ]
    run grep -F '@~/.agents/AGENTS.md' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(< "${CLAUDE_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/CLAUDE.md" ]
    [ "$(< "${CLAUDE_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/agents" ]
}

@test "[common] tool-specific agent wrappers point to shared agent instructions" {
    [ -f "${SHARED_GH_AGENT_PATH}" ]
    [ -f "${SHARED_WORKLOG_AGENT_PATH}" ]
    [ -f "${CLAUDE_GH_AGENT_PATH}" ]
    [ -f "${CLAUDE_WORKLOG_AGENT_PATH}" ]
    [ -f "${CODEX_GH_AGENT_PATH}" ]
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]

    run grep -F 'read ~/.agents/agents/gh-workflow-manager.md and follow it as your primary instructions.' "${CLAUDE_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'read ~/.agents/agents/worklog-manager.md and follow it as your primary instructions.' "${CLAUDE_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'read ~/.agents/agents/gh-workflow-manager.md and follow it as your primary instructions.' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'read ~/.agents/agents/worklog-manager.md and follow it as your primary instructions.' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex worklog is delegated to the custom subagent" {
    [ -f "${CODEX_WORKLOG_AGENT_PATH}" ]
    [ -f "${SHARED_WORKLOG_AGENT_PATH}" ]

    run grep -F 'name = "worklog-manager"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'You are the dedicated worklog manager for agent sessions in this repository.' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '~/.agents/skills/worklog-manager/SKILL.md' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'source of truth for startup learn selection, plan/todo/learn metadata, stale-learn hard gating, and audit behavior' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "startup audit is mandatory" "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Do not continue startup with best-effort learn selection." "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`Active learnings`, `Needs revalidation`, `Ignored historical entries`' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'CONFLICT_REPORT' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'source_type: startup_fact|plan_assumption|todo' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'CONFIRM_OVERRIDE' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'REJECT_OVERRIDE' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'NEEDS_USER_CLARIFICATION' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Do not write `.agents/worklog/codex/**` before confirmation.' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'pending_revalidation' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Required `learn` keys:' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'Keep `todo.status` within' "${SHARED_WORKLOG_AGENT_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F "worklog-manager" "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '$(date +%Y%m%d_%H%M%S)_plan.md' "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "#### plan/todo/learn の frontmatter ルール" "${CODEX_CODEX_ONLY_PATH}"
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
    run grep -F '`startup facts`' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'are context only and are not `startup facts`.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'CONFLICT_REPORT' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'source_type: startup_fact|plan_assumption|todo' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'CONFIRM_OVERRIDE' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'REJECT_OVERRIDE' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'NEEDS_USER_CLARIFICATION' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Do not write `.agents/worklog/codex/**` before confirmation.' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'learn_update: pending_revalidation' "${CODEX_WORKLOG_SKILL_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'The audit validates corpus integrity, not parent confirmation flow.' "${CODEX_WORKLOG_SKILL_PATH}"
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
    run grep -F 'Session-local override is not a corpus migration.' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Session-local overrides are governed by the conflict contract, not by audit.' "${CODEX_WORKLOG_RULES_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'default_prompt: "Use $worklog-manager to manage Codex worklog files and audit stale learn metadata."' "${CODEX_WORKLOG_SKILL_OPENAI_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex GitHub workflow is delegated to the custom subagent" {
    [ -f "${CODEX_GH_AGENT_PATH}" ]
    [ -f "${SHARED_GH_AGENT_PATH}" ]
    [ ! -e "${LEGACY_GH_FIRST_SKILL_PATH}" ]

    run grep -F 'name = "gh-workflow-manager"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'sandbox_mode = "workspace-write"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'You are the dedicated GitHub workflow manager for agent sessions in this repository.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Never read or write `.agents/worklog/**`.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "gh-workflow-manager" "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "gh-first-workflow" "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "gh pr create" "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F "git rev-parse --show-toplevel" "${CODEX_CODEX_ONLY_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F 'Do not treat "PR created" or "PR updated" as task completion when CI verification is still pending.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'stay responsible until the required checks reach a terminal state and report that result explicitly.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] codex GitHub workflow defines PR description structure and template priority" {
    run grep -F 'first check whether the repository provides a pull request template and follow that structure when present' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'If no pull request template is available, use this default PR description structure:' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '  - `## Why`' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '  - `## What Changed`' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '  - `## Validation`' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'In either case, describe the full current PR, not only the latest delta.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Keep the `Validation` section repo-relative and never include local absolute paths.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'In the `Validation` section, prefer repeated command-based steps instead of bullet lists.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'For each command-based validation step, write one short natural-language line that explains what the command verified, then place the exact command in a fenced `shell` block.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Use descriptive lines such as `Check the updated guidance assertions.` or `Inspect the staged diff for formatting issues.`, not placeholder labels like `Try command 1`.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Repeat that pattern for each command-based validation step.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'If a validation item is not command-based, keep it as one short prose line without forcing a code block.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
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
    run grep -F "~/.agents/agents" "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/exact_agents/agents/" "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.claude" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/claude/" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.claude/agents" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/codex/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "symlink_AGENTS.md.tmpl" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/AGENTS.codex-only.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "symlink_AGENTS.codex-only.md.tmpl" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.codex-only.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/codex/agents/" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Codex TOML wrappers" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Edit the canonical source, not this adapter directory." "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.agents" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'The `exact_` segment in this path is a chezmoi source-state attribute' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'https://www.chezmoi.io/reference/source-state-attributes/' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'dot_` changes a target name to start with `.`' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'exact_` removes entries in the target directory that are not explicitly managed in the source state' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '.config/agents' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '../../.chezmoitemplates/chezmoiignore.d/common' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../exact_dot_agents/" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'read first from `~/.codex/AGENTS.md` before `~/.codex/AGENTS.codex-only.md`' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '@~/.agents/AGENTS.md' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Claude Markdown wrappers and Codex TOML wrappers explicitly tell each tool to read the same shared Markdown first" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.codex-only.md" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "The diagram below describes this repository's source-of-truth layout" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.claude" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_claude/" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '@~/.agents/AGENTS.md' "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.claude/agents" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'read `~/.agents/agents/<name>.md` first' "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "It is the Codex entrypoint" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_codex/symlink_AGENTS.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/AGENTS.codex-only.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_codex/symlink_AGENTS.codex-only.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "AGENTS.codex-only.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "(agents/)" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Codex TOML wrappers" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "keeps the home path stable" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] layout docs and adapter-only config paths stay repo-only" {
    [ -f "${CHEZMOIIGNORE_PATH}" ]

    run grep -Fx ".agents/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".claude/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".codex/README.md" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fx ".config/agents" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}
