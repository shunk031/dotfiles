---
name: worklog-manager
description: Manage Codex worklog files under `.agents/worklog/codex`, hard-gate stale learnings through `learn_index.md`, and audit learn metadata deterministically. Use when a Codex agent or user needs to bootstrap worklog context, maintain plan/todo/learn files, or validate stale learn state before trusting prior session knowledge.
---

# Worklog Manager

## Overview

Use this skill to manage `.agents/worklog/codex/**` for Codex sessions.
It keeps startup context constrained to valid learn entries, maintains plan/todo/learn metadata, and audits stale learn state deterministically.

## When To Use

- Bootstrap or update `.agents/worklog/codex/{plan,todo,learn}` for a non-trivial Codex task.
- Summarize reusable learnings before implementation starts.
- Create, update, supersede, or archive reusable learn files.
- Audit stale learn metadata or index consistency before trusting older session knowledge.

## Workflow

1. Keep scope limited to `.agents/worklog/codex/**`. If the request needs repo edits, GitHub operations, or product decisions, hand that back to the parent agent.
2. Bootstrap from `.agents/worklog/codex/learn/learn_index.md`.
   - Ensure `.agents/worklog/codex/plan/`, `todo/`, and `learn/` exist.
   - Treat `## Active` as the only startup source of truth.
   - Treat `## Needs Review` as context candidates, not facts.
   - Ignore `## Superseded` and `## Archived` unless the parent explicitly asks for history or migration context.
   - Read only the learn files referenced by the relevant index entries.
   - Return the startup summary in this exact order:
     - `Active learnings`: only `active` entries with `freshness: stable`.
     - `Needs revalidation`: every `needs_review` entry plus any `active` entry with `freshness: drift_prone`.
     - `Ignored historical entries`: relevant `superseded` or `archived` entries that were intentionally skipped.
3. Maintain the session plan and todo continuously while the parent works.
   - Required common keys: `type`, `id`, `owner`, `created_at`, `updated_at`.
   - Required `plan` key: `status`.
   - Required `todo` keys: `status`, `workstream`, `related_plan`.
   - Required `learn` keys: `validated`, `apply_to`, `status`, `freshness`, `last_validated_at`.
   - Keep `todo.status` within `active | blocked | done | superseded`.
   - Keep `plan.status` within `draft | active | done | superseded`.
   - Use these headings for plan files: `User Prompt`, `Goal`, `Scope`, `Assumptions`, `Design`, `Tests`, `Open Questions`.
   - Use these headings for todo files: `TODO`, `Done`.
   - Use these headings for learn files: `Date`, `Learnings`, `Plan Updates`.
4. Manage learn metadata and index state together.
   - `status` must be one of `active | needs_review | superseded | archived`.
   - `freshness` must be one of `stable | drift_prone`.
   - `freshness: drift_prone` requires `review_after`.
   - `status: superseded` requires `superseded_by`.
   - Replacement learn files should declare `supersedes`.
   - `learn_index.md` must contain exactly these sections: `## Active`, `## Needs Review`, `## Superseded`, `## Archived`.
   - Keep each index entry on one line in this format:
     `- [Title](file.md) [stable|drift_prone] — Summary`
5. When learn changes affect the active plan, update the plan `Assumptions`, `Design`, or `Tests` sections to match.

## Learn Promotion Gate

- Do not promote session-local facts, current branch names, current paths, default-branch names, or any repo state that is cheap to re-check right now.
- Only store drift-prone repo state when repeated reuse has justified the cost. When you do, mark it `freshness: drift_prone` and set an explicit `review_after`.
- When you encounter legacy branch/default-branch learns, do targeted migration instead of broad corpus rewrites.
  - A fact like `default branch is master` must not stay `active`; move it to `superseded`.
  - A recipe that still assumes `origin/master` should move to `needs_review` until it is revalidated against the current `main` workflow.

## Audit

Use the bundled audit helper before trusting an older corpus or after changing learn metadata:

```bash
uv run python ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py summary
uv run python ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py check
```

Use `--learn-root <path>` when you need to audit fixtures or a non-default corpus.
Use `--now <ISO-8601>` when you need deterministic review expiry checks in tests.

## Output

- Keep responses concise.
- When the parent asks for a close-out summary, return a one-line candidate that starts with `📝 まとめ:`.

## References

- Read [learn_rules.md](references/learn_rules.md) when you need exact frontmatter examples, index examples, or the audit contract.

## Resources

### scripts/

- `scripts/codex_worklog_audit.py`: deterministic audit helper for learn metadata, review expiry, supersession links, and index/file consistency.

### references/

- `references/learn_rules.md`: detailed learn metadata rules, targeted migration examples, and audit expectations.
