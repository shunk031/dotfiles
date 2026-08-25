#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly ROOT_AGENTS_PATH="./AGENTS.md"
readonly SHARED_GH_AGENT_PATH="./home/dot_config/exact_agents/agents/gh-workflow-manager.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_GH_AGENT_PATH="./home/dot_config/codex/agents/gh-workflow-manager.toml"
readonly LEGACY_GH_FIRST_SKILL_PATH="./home/dot_config/exact_agents/skills/gh-first-workflow"
readonly AGENT_GUIDANCE_REQUIREMENTS_PATH="./tests/fixtures/agent_guidance_requirements.json"
readonly AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH="./tests/python/test_agent_guidance_requirements.py"
readonly GUIDANCE_EVAL_SCRIPT="./scripts/agent_guidance_eval.py"
readonly PREK_CONFIG_PATH="./.pre-commit-config.yaml"
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
readonly CLAUDE_SKILLS_KEEP_PATH="./home/dot_claude/skills/.keep"
readonly GITIGNORE_PATH="./.gitignore"

@test "[common] codex guidance entrypoint stays minimal and reads shared guidance" {
    [ -f "${SHARED_AGENTS_PATH}" ]
    [ -f "${CODEX_AGENTS_PATH}" ]
    [ ! -e "./home/dot_config/codex/AGENTS.codex-only.md" ]
    [ ! -e "./home/dot_codex/symlink_AGENTS.codex-only.md.tmpl" ]

    run grep -F '> After reading this `AGENTS.md`, say: `🤖 I read ~/.codex/AGENTS.md.`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Shared instructions: Read `~/.agents/AGENTS.md` first' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Codex-Specific Delegation' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'native subagents' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'gh-workflow-manager' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared guidance defines highest-priority implementation principles" {
    run grep -F '## Most Important Implementation Principles' "${SHARED_AGENTS_PATH}"
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
    run grep -F 'Do not worry about backward compatibility.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared guidance keeps only cross-task invariants" {
    run grep -F '## Work Safety' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Preserve changes owned by the user or a concurrent agent: read their before and after states and context before excluding or reverting them' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'do not infer relevance from a filename or the latest task' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'never revert without proof and permission' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'isolate exclusions with another task worktree or narrow staging, or ask first' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output. Do not perform additional overwrites before recovery.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '## Writing Instructions' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Writing GitHub Issue and PR Comments' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Self-Improvement' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '## Working Style' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '## Questions for the User' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Implementation' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## Guidance Ownership' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F '## GitHub Workflow' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'identify a reusable prevention that addresses the root cause' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Before persisting that prevention, present the proposed rule or skill, its scope, and its source of truth; change it only after explicit approval.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Persist only concise, generalizable prevention.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'use `shunk031-manage-agent-guidance` to place it without duplication' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'Use the `shunk031-manage-agent-guidance` skill when adding, moving, or deleting persistent instructions, agent wrappers, or skills.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -Fc 'Use the `shunk031-manage-agent-guidance` skill when adding, moving, or deleting persistent instructions, agent wrappers, or skills.' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1" ]
    run grep -F 'Use `shunk031-structured-writing`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'Delegate GitHub issue, branch, commit, push, PR, and CI workflows to `gh-workflow-manager` by default' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] shared guidance delegates detailed worktree mechanics" {
    run grep -F 'never pass the base ref as the second `gwq add` argument' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F 'run `git merge --ff-only origin/main` inside the new worktree' "${SHARED_AGENTS_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F 'gh-workflow-manager' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Treat the default branch as read-only and use a task-specific worktree even when it is clean' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] workflow manager avoids shared FETCH_HEAD writes" {
    run grep -F '`git fetch --no-write-fetch-head origin main`' "${SHARED_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] root guidance keeps repository invariants and routes specialized procedures" {
    run grep -F '## Git / PR Workflow' "${ROOT_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'Agent skills:' "${ROOT_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'run `make setup` before editing or committing' "${ROOT_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'mise compatibility changes: When a tool or configuration change requires newer mise behavior, determine the minimum mise release that supports the change, raise `min_version` in the same pull request, and record the requirement in the pull request description.' "${ROOT_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'use the `shunk031-shdoc-shell-docs` skill for detailed conventions' "${ROOT_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Never run `bats` locally' "${ROOT_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'use GitHub Actions only when the push/CI workflow is separately authorized' "${ROOT_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '## mise Bootstrap Compatibility' "${ROOT_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'SKIP=agent-guidance-eval' "${ROOT_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'real model evaluation' "${ROOT_AGENTS_PATH}"
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

@test "[common] specialized guidance is delegated to a skill, not inlined here" {
    # The skill bodies moved to shunk031/skills. What this repository still owns
    # is the delegation: the guidance names each skill and says nothing more.
    # Asserting on the bodies from here would assert against a checkout this
    # repository does not control.
    [ ! -e "./home/dot_config/exact_agents/skills" ]

    run grep -F 'Use the `shunk031-manage-agent-guidance` skill' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'Use the `shunk031-research-before-implementation` skill' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] instruction migrations have a static completeness contract" {
    [ -f "${AGENT_GUIDANCE_REQUIREMENTS_PATH}" ]
    [ -f "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}" ]

    run grep -F '"version": 2' "${AGENT_GUIDANCE_REQUIREMENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '"source_id": "root-historical"' "${AGENT_GUIDANCE_REQUIREMENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '"disposition": "removed"' "${AGENT_GUIDANCE_REQUIREMENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '"thin_adapters"' "${AGENT_GUIDANCE_REQUIREMENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_owner_text_has_one_path_per_normalized_rule' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_each_historical_bullet_or_directive_has_semantic_requirements' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_repeated_source_fragments_have_explicit_occurrence_anchors' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_repeated_destination_fragments_have_explicit_occurrence_counts' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_semantic_inventory_preserves_material_subclauses' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_only_approved_rules_are_removed' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_mapped_requirements_exist_at_their_single_destination' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_expected_thin_adapters_are_complete_and_exclusive' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'test_guidance_reverse_scan_covers_every_guidance_file_here' "${AGENT_GUIDANCE_REQUIREMENTS_TEST_PATH}"
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

@test "[common] prek validates and evaluates changed managed skills and guidance" {
    [ -f "${PREK_CONFIG_PATH}" ]
    [ -f "${GUIDANCE_EVAL_SCRIPT}" ]

    run grep -F 'id: agent-guidance-validate' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'id: agent-guidance-eval' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'pass_filenames: false' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '"aqua:j178/prek" = "0.4.11"' ./home/dot_mise/config.toml
    [ "${status}" -eq 0 ]
}

@test "[common] Claude skills directory is a real, installer-writable directory" {
    [ -f "${CLAUDE_SKILLS_KEEP_PATH}" ]
    [ ! -s "${CLAUDE_SKILLS_KEEP_PATH}" ]
}

@test "[common] skill-creator remains installer-managed for Claude Code" {
    [ ! -e "${SKILL_CREATOR_SHARED_SKILL_PATH}" ]
    [ ! -e "${SKILL_CREATOR_SYMLINK_TEMPLATE}" ]
}

@test "[common] gitignore no longer allowlists repo-managed skills" {
    run grep -F "exact_agents/skills" "${GITIGNORE_PATH}"
    [ "${status}" -eq 1 ]
}
