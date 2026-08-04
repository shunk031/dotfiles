---
name: manage-agent-guidance
description: Organize persistent coding-agent guidance and its adapters without blindly editing a user-named file. Use when creating, converting, reviewing, or reorganizing AGENTS.md, CLAUDE.md, user-level instructions, custom-agent wrappers, or repo-local skills; when deciding whether a rule belongs at user, repository, subtree, task, or skill scope; or when preventing duplicated guidance across tools. Always establish scope, source of truth, and existing ownership before drafting or applying a persistent rule.
---

# Manage Agent Guidance

Keep each durable instruction in one source of truth and expose it through thin adapters.

## Required Gate

Before drafting or editing persistent guidance, report the evidence for all three decisions:

1. Scope: identify whether the behavior is user-level, repository-level, subtree-level, task-only, custom-agent, or skill guidance.
2. Source of truth: inspect higher-level instructions, managed sources, symlinks, imports, wrappers, and adapters.
3. Existing owner: search current guidance and skills for a workflow that already owns the behavior.

Do not produce the requested rule or edit until this gate is complete. If evidence is unavailable, ask for or propose the missing inspection instead of choosing the filename from the request.

## Workflow

1. Read all applicable guidance before proposing a change.
2. Treat a filename named in the request as a hypothesis, not as the confirmed edit target. Classify each rule as user-level, repository-level, subtree-level, task-only, custom-agent, or skill guidance.
3. Inspect the managed source, higher-level instructions, symlinks, imports, wrappers, and tool adapters.
4. Search existing guidance and skills for equivalent rules. Strengthen an existing source instead of adding a duplicate.
5. Put concise cross-task invariants in the applicable `AGENTS.md`. Put specialized repeatable procedures or domain knowledge in an existing relevant skill.
6. Create a new skill only when no existing skill fits and the procedure is substantial and reusable.
7. Review the final diff for scope mismatch, duplication, secrets, transient facts, and adapter drift.

When the available repository does not contain enough evidence, report the missing sources and propose the investigation instead of defaulting to the named file.

## Repository Wiring

- Keep repository conventions in the root `AGENTS.md`; do not repeat user-level rules there.
- Make root `CLAUDE.md` a relative symlink to `AGENTS.md`, not a copied file or an import stub.
- Keep repo-local skills at `.agents/skills/<name>/SKILL.md` and expose them to Claude with a relative `.claude/skills` symlink when required.
- Keep lengthy shared custom-agent instructions in `~/.agents/agents/<name>.md`. Preserve tool-specific metadata in thin Claude or Codex wrappers that direct the agent to the shared source.
- Keep private infrastructure, credentials, internal endpoints, and environment-specific launch configuration out of public guidance.

## Self-Improvement

- Apply a verified correction to the current task before proposing persistence.
- Persist only concise, actionable prevention guidance that generalizes beyond the incident.
- Obtain approval before adding or changing persistent guidance.
- Do not persist secrets, task-specific facts, transient state, incident narratives, or unverified assumptions.
