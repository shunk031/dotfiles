#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly SHARED_GH_AGENT_PATH="./home/dot_config/exact_agents/agents/gh-workflow-manager.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_GH_AGENT_PATH="./home/dot_config/codex/agents/gh-workflow-manager.toml"
readonly LEGACY_GH_FIRST_SKILL_PATH="./home/dot_config/exact_agents/skills/gh-first-workflow"
readonly SKILL_CREATOR_SHARED_SKILL_PATH="./home/dot_config/exact_agents/skills/skill-creator"
readonly SKILL_CREATOR_SYMLINK_TEMPLATE="./home/exact_dot_agents/skills/symlink_skill-creator.tmpl"
readonly AGENTS_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_AGENTS.md.tmpl"
readonly SHARED_AGENT_DIR_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_agents.tmpl"
readonly CLAUDE_MD_PATH="./home/dot_config/claude/CLAUDE.md"
readonly CLAUDE_SYMLINK_TEMPLATE="./home/dot_claude/symlink_CLAUDE.md.tmpl"
readonly CLAUDE_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_claude/symlink_agents.tmpl"
readonly CLAUDE_GH_AGENT_PATH="./home/dot_config/claude/agents/gh-workflow-manager.md"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly AGENTS_README_PATH="./home/exact_dot_agents/README.md"
readonly CLAUDE_README_PATH="./home/dot_claude/README.md"
readonly CODEX_README_PATH="./home/dot_codex/README.md"
readonly CANONICAL_AGENTS_README_PATH="./home/dot_config/exact_agents/README.md"
readonly CANONICAL_CLAUDE_README_PATH="./home/dot_config/claude/README.md"
readonly CANONICAL_CODEX_README_PATH="./home/dot_config/codex/README.md"
readonly SHARED_SKILLS_SYMLINK_DIR="./home/exact_dot_agents/skills"
readonly CLAUDE_SKILLS_KEEP_PATH="./home/dot_claude/skills/.keep"
readonly CLAUDE_SKILL_DIR_SYMLINK_TEMPLATE="./home/dot_claude/symlink_skills.tmpl"
readonly GEMINI_SKILLS_SYMLINK_DIR="./home/dot_gemini/config/skills"
readonly GEMINI_SKILL_DIR_SYMLINK_TEMPLATE="./home/dot_gemini/config/symlink_skills.tmpl"
readonly LINK_SHARED_SKILLS_SCRIPT="./home/.chezmoiscripts/common/run_after_90-link-shared-skills.sh.tmpl"
readonly GITIGNORE_PATH="./.gitignore"

@test "[common] codex guidance entrypoint stays minimal and reads shared guidance" {
    [ -f "${SHARED_AGENTS_PATH}" ]
    [ -f "${CODEX_AGENTS_PATH}" ]
    [ ! -e "./home/dot_config/codex/AGENTS.codex-only.md" ]
    [ ! -e "./home/dot_codex/symlink_AGENTS.codex-only.md.tmpl" ]

    run grep -F '> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS.md` を最初に読み' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Codex 固有の委譲' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'native subagents' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'gh-workflow-manager' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared guidance defines highest-priority implementation principles" {
    run grep -F '## 最重要の実装原則' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'These principles take precedence over other implementation guidance in this file.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Do not preserve backward compatibility.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Choose the simplest implementation that fully meets the current requirements.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Prefer established, well-maintained libraries over custom implementations.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '後方互換性は気にしないでください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
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

@test "[common] shared guidance protects uncommitted diffs" {
    run grep -F '## 未コミット差分の保護' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '自分が作ったと明確に証明できない差分を、明示的な許可なしに戻してはいけません' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '差分を戻すのではなく、stage 対象を限定する、別 worktree を使う、またはユーザーへ確認してください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance prevents gwq base-ref misuse" {
    run grep -F 'base ref のつもりで `origin/main` などを渡してはいけません' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'worktree へ移動してから `git merge --ff-only origin/main` を実行してください' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
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
    run grep -F '同じ長文指示を wrapper にコピーしないでください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Markdown を Python などでパースして TOML / Markdown を生成する仕組みは、明示的に必要になるまで追加しないでください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance defines tool-neutral native delegation policy" {
    run grep -F '## 実装タスクの委譲' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '利用中の coding agent が native multi-agent 機能を提供し、タスクを独立した単位に分けられる場合' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Claude Code の agent teams や Codex の subagents など、各 tool の native 機能を使ってください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'subagent が使うモデルや起動方法などの環境固有設定は、このファイルには書かず `~/.agents/AGENTS-private.md` または tool 固有 entrypoint を参照してください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/AGENTS.md" ]
    [ "$(< "${SHARED_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/agents" ]
    run grep -F '@~/.agents/AGENTS.md' "${CLAUDE_MD_PATH}"
    [ "${status}" -eq 0 ]
    [ "$(< "${CLAUDE_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/CLAUDE.md" ]
    [ "$(< "${CLAUDE_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/agents" ]
    [ "$(< "${CODEX_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/AGENTS.md" ]
    [ "$(< "${CODEX_AGENT_DIR_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/agents" ]
}

@test "[common] tool-specific agent wrappers point to shared agent instructions" {
    [ -f "${SHARED_GH_AGENT_PATH}" ]
    [ -f "${CLAUDE_GH_AGENT_PATH}" ]
    [ -f "${CODEX_GH_AGENT_PATH}" ]

    run grep -F 'read ~/.agents/agents/gh-workflow-manager.md and follow it as your primary instructions.' "${CLAUDE_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Read ~/.agents/agents/gh-workflow-manager.md first and follow it as your primary instructions.' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'name = "gh-workflow-manager"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'developer_instructions = ' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] GitHub workflow is delegated to the custom subagent" {
    [ -f "${SHARED_GH_AGENT_PATH}" ]
    [ ! -e "${LEGACY_GH_FIRST_SKILL_PATH}" ]

    run grep -F 'You are the dedicated GitHub workflow manager for agent sessions in this repository.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Never read or write `.agents/worklog/**`.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Do not treat "PR created" or "PR updated" as task completion when CI verification is still pending.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'stay responsible until the required checks reach a terminal state and report that result explicitly.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] GitHub workflow defines PR description structure and template priority" {
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

    run grep -F 'Write multi-line GitHub issue, pull request, and comment bodies to a temporary Markdown file with a single-quoted heredoc, then submit them with `--body-file`.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'Do not pass multi-line Markdown through `--body "...\n..."`; escaped newlines can be published literally instead of becoming Markdown line breaks.' "${SHARED_GH_AGENT_PATH}"
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

    run grep -F 'After creating or editing repository-facing GitHub text, read it back with `gh pr view`, `gh issue view`, or equivalent JSON output before reporting completion.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'The read-back check must reject or report literal escaped newlines (`\n`) and local absolute paths such as `/Users/`, and confirm the expected Markdown headings and content are present.' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance rejects inline multi-line GitHub bodies" {
    run grep -F 'GitHub issue body / PR description / PR comment のような multi-line Markdown は、必ず一時 Markdown file を single-quoted heredoc で作り、`gh ... --body-file <file>` で投稿・更新してください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F '`gh ... --body "...\n..."` や shell-escaped multi-line body の直渡しは、literal `\n` が公開されるため使わないでください。' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F 'literal escaped newlines (`\n`)、local absolute paths such as `/Users/`、期待見出しの欠落を検出してから完了報告してください。' "${SHARED_AGENTS_PATH}"
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
    run grep -F "~/.codex/agents" "${CODEX_README_PATH}"
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
    run grep -F '@~/.agents/AGENTS.md' "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "Claude and Codex wrappers explicitly tell each tool to read the same shared Markdown first" "${CANONICAL_AGENTS_README_PATH}"
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
    run grep -F "../../dot_codex/symlink_AGENTS.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "private dotfiles" "${CANONICAL_CODEX_README_PATH}"
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
    run grep -Fx ".config/codex" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] repository Claude entrypoint is an AGENTS.md symlink" {
    [ -L "./CLAUDE.md" ]
    [ "$(readlink ./CLAUDE.md)" = "AGENTS.md" ]
}

@test "[common] shared skills pool exposes repo-managed skills through per-skill symlink templates" {
    [ ! -e "./home/exact_dot_agents/symlink_skills.tmpl" ]
    [ ! -e "${CLAUDE_SKILL_DIR_SYMLINK_TEMPLATE}" ]
    [ ! -e "${GEMINI_SKILL_DIR_SYMLINK_TEMPLATE}" ]
    [ -d "${SHARED_SKILLS_SYMLINK_DIR}" ]

    [ "$(< "${SHARED_SKILLS_SYMLINK_DIR}/symlink_humanizer-ja.tmpl")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/humanizer-ja" ]
    [ "$(< "${SHARED_SKILLS_SYMLINK_DIR}/symlink_setup-agent-docs.tmpl")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/setup-agent-docs" ]
    [ "$(< "${SHARED_SKILLS_SYMLINK_DIR}/symlink_shdoc-shell-docs.tmpl")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/shdoc-shell-docs" ]
}

@test "[common] Gemini skills expose repo-managed skills through per-skill symlink templates" {
    [ -d "${GEMINI_SKILLS_SYMLINK_DIR}" ]

    local skills="ai-slop-checklist-ja cgd-dev-identity convert-to-transformers gh-comment-attach-files high-impact-journal-publishing humanizer-ja python-uv-workflow setup-agent-docs shdoc-shell-docs"
    local skill
    local template
    local expected

    for skill in ${skills}; do
        template="${GEMINI_SKILLS_SYMLINK_DIR}/symlink_${skill}.tmpl"
        expected="{{ .chezmoi.sourceDir }}/dot_config/exact_agents/skills/${skill}"
        [ -f "${template}" ]
        [ "$(< "${template}")" = "${expected}" ]
    done

    [ ! -e "${GEMINI_SKILLS_SYMLINK_DIR}/symlink_agmsg.tmpl" ]
    [ ! -e "${GEMINI_SKILLS_SYMLINK_DIR}/symlink_delegate-codex.tmpl" ]
    [ ! -e "${GEMINI_SKILLS_SYMLINK_DIR}/symlink_herdr.tmpl" ]
    [ ! -e "${GEMINI_SKILLS_SYMLINK_DIR}/symlink_skill-creator.tmpl" ]
    [ ! -e "${GEMINI_SKILLS_SYMLINK_DIR}/symlink_worklog-manager.tmpl" ]
}

@test "[common] Claude skills directory is a real, installer-writable directory" {
    [ -f "${CLAUDE_SKILLS_KEEP_PATH}" ]
    [ ! -s "${CLAUDE_SKILLS_KEEP_PATH}" ]
}

@test "[common] skill-creator remains installer-managed for Claude Code" {
    [ ! -e "${SKILL_CREATOR_SHARED_SKILL_PATH}" ]
    [ ! -e "${SKILL_CREATOR_SYMLINK_TEMPLATE}" ]
}

@test "[common] run_after script subscribes tool skills directories to the shared pool" {
    [ -f "${LINK_SHARED_SKILLS_SCRIPT}" ]

    run grep -F 'POOL="${HOME}/.agents/skills"' "${LINK_SHARED_SKILLS_SCRIPT}"
    [ "${status}" -eq 0 ]
    run grep -F '"${HOME}/.claude/skills"' "${LINK_SHARED_SKILLS_SCRIPT}"
    [ "${status}" -eq 0 ]
    run grep -F '{{ if ne (env "CI") "true" -}}' "${LINK_SHARED_SKILLS_SCRIPT}"
    [ "${status}" -eq 0 ]

    # Never clobber a real, installer-written entry with a pool symlink.
    run grep -F 'if [ -e "${target}" ] && [ ! -L "${target}" ]; then' "${LINK_SHARED_SKILLS_SCRIPT}"
    [ "${status}" -eq 0 ]

    # Prune dangling pool symlinks whose pool entry has been removed.
    run grep -F 'if [ ! -e "${link_target}" ]; then' "${LINK_SHARED_SKILLS_SCRIPT}"
    [ "${status}" -eq 0 ]
}

@test "[common] gitignore no longer allowlists repo-managed skills" {
    run grep -F "exact_agents/skills" "${GITIGNORE_PATH}"
    [ "${status}" -eq 1 ]
}
