#!/usr/bin/env bats

readonly SHARED_AGENTS_PATH="./home/dot_config/agents/AGENTS.md"
readonly CODEX_AGENTS_PATH="./home/dot_config/codex/AGENTS.md"
readonly CODEX_SYMLINK_TEMPLATE="./home/dot_codex/symlink_AGENTS.md.tmpl"
readonly AGENTS_SYMLINK_TEMPLATE="./home/dot_agents/symlink_AGENTS.md.tmpl"
readonly CLAUDE_MD_PATH="./home/dot_config/claude/CLAUDE.md"
readonly CLAUDE_SYMLINK_TEMPLATE="./home/dot_claude/symlink_CLAUDE.md.tmpl"

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

@test "[common] agent guidance adapters point to the canonical files" {
    [ "$(< "${AGENTS_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/agents/AGENTS.md" ]
    [ "$(< "${CODEX_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/codex/AGENTS.md" ]
    [ "$(< "${CLAUDE_MD_PATH}")" = "@~/.agents/AGENTS.md" ]
    [ "$(< "${CLAUDE_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_config/claude/CLAUDE.md" ]
}
