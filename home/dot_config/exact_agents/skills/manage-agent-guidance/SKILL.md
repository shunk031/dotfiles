---
name: manage-agent-guidance
description: Organize persistent coding-agent guidance and its adapters without blindly editing a user-named file. Use when creating, converting, reviewing, or reorganizing AGENTS.md, CLAUDE.md, user-level instructions, custom-agent wrappers, or repo-local skills; when deciding whether a rule belongs at user, repository, subtree, task, or skill scope; or when preventing duplicated guidance across tools. Always establish scope, source of truth, and existing ownership before drafting or applying a persistent rule.
---

# Manage Agent Guidance

Keep each durable instruction in one source of truth and expose it through thin adapters.

## Workflow

1. Read all applicable guidance before proposing a change.
2. Classify each rule as user-level, repository-level, subtree-level, task-only, custom-agent, or skill guidance. Treat a filename named in the request as a hypothesis, not as the confirmed target.
3. Locate the source of truth by inspecting higher-level instructions, managed sources, symlinks, imports, wrappers, and adapters.
4. Search current guidance and skills for an existing owner. Strengthen that owner instead of adding a duplicate.
5. Before drafting or editing, report the evidence for scope, source of truth, and existing ownership. Name the inspected files, adapters, and matching owner rule; if none exists, state where you searched.
6. Put concise cross-task invariants in the applicable `AGENTS.md` and specialized repeatable procedures in an existing relevant skill. Create a skill only when no existing owner fits and the procedure is substantial and reusable.
7. Review the final diff for scope mismatch, duplication, secrets, transient facts, and adapter drift.

Do not draft or edit until steps 2–5 are complete. When evidence is unavailable, report the missing sources and propose the investigation instead of defaulting to the named file.

## Instruction Migrations

1. Inventory every atomic rule in the source before deleting or compressing any section.
2. Record one destination for every rule: always-on guidance, an existing skill, a custom agent, repository guidance, or an explicitly approved removal.
3. Build a reverse index from each normalized rule to every destination and related guidance file, not only from the source to its proposed destination. Assign each rule exactly one authoritative owner, remove redundant copies, and record only intentional thin adapters as exceptions.
4. Preserve examples when they disambiguate behavior that prose alone does not reliably produce.
5. Add or update a static migration contract that fails when a mapped requirement disappears or a known duplicate remains outside its authoritative owner.
6. Add behavioral evals for the moved capability, but never treat model evals as proof that every source requirement was migrated.
7. Present every proposed removal and its rationale to the user. Do not delete an unmapped or unapproved rule.

## Repository Wiring

- Keep repository conventions in the root `AGENTS.md`; do not repeat user-level rules there.
- Make root `CLAUDE.md` a relative symlink to `AGENTS.md`, not a copied file or an import stub.
- Keep repo-local skills at `.agents/skills/<name>/SKILL.md` and expose them to Claude with a relative `.claude/skills` symlink when required.
- Keep lengthy shared custom-agent instructions in `~/.agents/agents/<name>.md`. Preserve tool-specific metadata in thin Claude or Codex wrappers that direct the agent to the shared source.
- Keep private infrastructure, credentials, internal endpoints, and environment-specific launch configuration out of public guidance.
- Do not introduce a Markdown parser or generator to duplicate shared instructions into TOML or Markdown until that mechanism is explicitly needed.
