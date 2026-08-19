---
name: shunk031-manage-agent-guidance
description: Organize persistent coding-agent guidance and its adapters without blindly editing a user-named file. Use when creating, converting, reviewing, or reorganizing AGENTS.md, CLAUDE.md, user-level instructions, custom-agent wrappers, or repo-local skills; when deciding whether a rule belongs at user, repository, subtree, task, or skill scope; or when preventing duplicated guidance across tools. Always establish scope, source of truth, and existing ownership before drafting or applying a persistent rule.
---

# Manage Agent Guidance

Keep each durable instruction in one source of truth and expose it through thin adapters.

## Workflow

1. Read all applicable guidance before proposing a change.
2. Classify each rule as user-level, repository-level, subtree-level, task-only, custom-agent, or skill guidance. Treat a filename named in the request as a hypothesis, not as the confirmed target. Put behavioral rules shared across repositories at the user level, configuration and procedures for one repository at the repository level, and rules for a specific directory subtree at the subtree level.
3. Locate the source of truth by inspecting higher-level instructions, managed sources, symlinks, imports, wrappers, and adapters. Edit that source for the classified scope instead of duplicating a rule across repository-level AGENTS.md files.
4. Build a consumer map for every candidate overlap: record each canonical source, rendered path, actual reader, co-loaded higher-scope guidance, and standalone portability requirement. Matching wording does not prove redundant ownership, and different scope labels do not prove independent consumption. Decide separately for each consumer path instead of keeping or removing every copy as a group.
5. Search current guidance and skills for an existing owner. Strengthen that owner instead of adding a duplicate.
6. Before drafting or editing, report the evidence for scope, source of truth, existing ownership, and the consumer map. Name the inspected files, adapters, actual readers, and matching owner rule; if any are unknown, state what remains unverified.
7. Follow the scope-classification and source-of-truth rules above. Put concise cross-task invariants in the applicable `AGENTS.md` and specialized repeatable procedures in an existing relevant skill. Create a skill only when no existing owner fits and the procedure is substantial and reusable.
8. Before committing or creating a PR, review the diff for each added instruction to confirm that its location matches its scope and that it does not duplicate higher-scope guidance; move it to the correct source of truth when the scope does not match, or ask before changing external state when it is unclear.
9. Review the final diff for scope mismatch, duplication, secrets, transient facts, and adapter drift.

Do not draft or edit until steps 2–6 are complete. When evidence is unavailable, report the missing sources and propose the investigation instead of defaulting to the named file.

## Persistence Quality

- Persist only concise, actionable prevention that generalizes beyond the incident and states a reusable root-cause safeguard.
- Exclude secrets, task-specific facts, transient state, incident narratives, and unverified assumptions.
- Persistent guidance never references issue/PR numbers, migration tracking status, or other facts that expire. Guidance files are loaded indefinitely, but these facts have deadlines: the issue closes, the migration finishes, and the bare number becomes unresolvable outside its tracker — leaving future readers a rule they can neither verify nor act on. Record expiring facts in the issue tracker or a dated research note instead.

## Instruction Migrations

Before assigning a destination, inspect code, adjacent configuration comments, tests, CI, schemas, and automation for an existing machine-enforced owner. Keep prose only when human or agent judgment remains and omission would materially change behavior. Treat incidents as reasons to improve enforcement, not permanent prose. When enforcement fully owns behavior, propose removal with concrete evidence and obtain approval rather than mapping it into `AGENTS.md` or a new skill.

1. Inventory every atomic rule in the source before deleting or compressing any section.
2. Record one destination for every rule: always-on guidance, an existing skill, a custom agent, repository guidance, or an explicitly approved removal.
3. Build a reverse index from each normalized rule to every destination and related guidance file, not only from the source to its proposed destination. Assign each rule exactly one authoritative owner, remove redundant copies, and record only intentional thin adapters as exceptions.
4. For every approved removal, record the exact source requirement (ID and text) and a non-empty rationale in the static migration contract and migration deliverable.
5. For every intentional thin adapter, record its exact path, exact minimal text or syntax, authoritative owner/destination, and why the exception is necessary.
6. Name the existing owner skill or guidance file for every mapped destination; a category label alone is insufficient.
7. Preserve examples when they disambiguate behavior that prose alone does not reliably produce.
8. Add or update a static migration contract that fails when a mapped requirement disappears or a known duplicate remains outside its authoritative owner.
9. Add behavioral evals for the moved capability, but never treat model evals as proof that every source requirement was migrated.
10. In the final reverse audit, scan every guidance path for duplicate ownership and confirm that only recorded thin-adapter exceptions remain.
11. Present every proposed removal and its rationale to the user. Do not delete an unmapped or unapproved rule.
12. When a migration description or plan is requested, output the source, destination, removal, adapter, and reverse-audit records concretely rather than merely saying they should exist.

## Repository Validation

- For work in this public dotfiles repository, run guidance evaluation locally through `prek`.
- In this public dotfiles repository, use `SKIP=agent-guidance-eval` only for an emergency.
- Never skip static validation in this public dotfiles repository.
- For this public dotfiles repository, run real model evaluation locally, not in CI.
- For this public dotfiles repository, CI may test the evaluation runner only with a fake `codex` executable.

## Repository Wiring

- Keep repository conventions in the root `AGENTS.md`; do not repeat user-level rules there.
- Make root `CLAUDE.md` a relative symlink to `AGENTS.md`, not a copied file or an import stub.
- Keep repo-local skills at `.agents/skills/<name>/SKILL.md` and expose them to Claude with a relative `.claude/skills` symlink when required.
- Keep lengthy shared custom-agent instructions in `~/.agents/agents/<name>.md`. Preserve tool-specific metadata in thin Claude or Codex wrappers that direct the agent to the shared source.
- Keep private infrastructure, credentials, internal endpoints, and environment-specific launch configuration out of public guidance.
- Do not introduce a Markdown parser or generator to duplicate shared instructions into TOML or Markdown until that mechanism is explicitly needed.
