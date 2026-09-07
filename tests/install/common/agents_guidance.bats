#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/exact_agents/AGENTS.md"
readonly SHARED_GH_AGENT_PATH="./home/dot_config/exact_agents/agents/gh-workflow-manager.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly CODEX_AGENT_DIR_SYMLINK_TEMPLATE="./home/dot_codex/symlink_agents.tmpl"
readonly CODEX_GH_AGENT_PATH="./home/dot_config/codex/agents/gh-workflow-manager.toml"
readonly LEGACY_GH_FIRST_SKILL_PATH="./home/dot_config/exact_agents/skills/gh-first-workflow"
readonly GUIDANCE_EVAL_SCRIPT="./scripts/agent_guidance_eval.py"
readonly GUIDANCE_GATE_SCRIPT="./scripts/shuhari_guidance_gate.sh"
readonly PREK_CONFIG_PATH="./.pre-commit-config.yaml"
readonly SKILL_CREATOR_SHARED_SKILL_PATH="./home/dot_config/exact_agents/skills/skill-creator"
readonly SKILL_CREATOR_SYMLINK_TEMPLATE="./home/exact_dot_agents/skills/symlink_skill-creator.tmpl"
readonly AGENTS_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_AGENTS.md.tmpl"
readonly PRIVATE_AGENTS_SYMLINK_TEMPLATE="./home/exact_dot_agents/symlink_AGENTS-private.md.tmpl"
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

    run grep -F '~/.agents/AGENTS.md' "${CODEX_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '`~/.agents/AGENTS-private.md`' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
    run grep -F 'gh-workflow-manager' "${CODEX_AGENTS_PATH}"
    [ "${status}" -ne 0 ]
}

@test "[common] shared guidance routes worktree operations to the workflow manager" {
    run grep -Fc 'gh-workflow-manager' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" -ge 1 ]
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

    run grep -Fc 'shunk031-manage-agent-guidance' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
    run grep -Fc 'shunk031-research-before-implementation' "${SHARED_AGENTS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
}

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/exact_agents/AGENTS.md" ]
    [ "$(< "${PRIVATE_AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.homeDir }}/.local/share/chezmoi-private/home/dot_config/codex/AGENTS-private.md" ]
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

    run grep -F 'name = "gh-workflow-manager"' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'developer_instructions = ' "${CODEX_GH_AGENT_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] GitHub workflow is delegated to the custom subagent" {
    [ -f "${SHARED_GH_AGENT_PATH}" ]
    [ ! -e "${LEGACY_GH_FIRST_SKILL_PATH}" ]
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
    run grep -F "~/.claude" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/claude/" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.claude/agents" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../dot_config/codex/AGENTS.md" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.codex/agents" "${CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents" "${CANONICAL_AGENTS_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'https://www.chezmoi.io/reference/source-state-attributes/' "${CANONICAL_AGENTS_README_PATH}"
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
    run grep -F "~/.claude" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_claude/" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '@~/.agents/AGENTS.md' "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.claude/agents" "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F '~/.agents/agents/<name>.md' "${CANONICAL_CLAUDE_README_PATH}"
    [ "${status}" -eq 0 ]

    run grep -F "~/.codex/AGENTS.md" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "../../dot_codex/symlink_AGENTS.md.tmpl" "${CANONICAL_CODEX_README_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F "~/.agents/agents" "${CANONICAL_CODEX_README_PATH}"
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

@test "[common] prek validates and evaluates changed guidance" {
    [ -f "${PREK_CONFIG_PATH}" ]

    # The Python harness and its two hooks are gone: it evaluated the in-tree
    # skills, and that tree moved to shunk031/skills. What remains here is the
    # shared guidance, which Shuhari evaluates.
    [ ! -e "${GUIDANCE_EVAL_SCRIPT}" ]
    run grep -F 'agent-guidance-' "${PREK_CONFIG_PATH}"
    [ "${status}" -ne 0 ]

    run grep -F 'id: shuhari-validate-instructions' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'id: shuhari-eval-instructions' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    run grep -F 'pass_filenames: false' "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]

    # Both hooks reach Shuhari through the wrapper, which is where the
    # execution environment can be described. An inline entry could not be
    # told which sandbox a machine can actually provide.
    run grep -Fc "entry: ${GUIDANCE_GATE_SCRIPT#./} " "${PREK_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2" ]
    [ -x "${GUIDANCE_GATE_SCRIPT}" ]

    # Skipping a gate ships unmeasured guidance, so nothing here advertises the
    # escape hatch.
    run grep -F 'SKIP=shuhari-eval-instructions' "${PREK_CONFIG_PATH}"
    [ "${status}" -ne 0 ]
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
