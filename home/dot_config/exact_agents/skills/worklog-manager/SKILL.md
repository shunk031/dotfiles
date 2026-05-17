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
   - If `learn_index.md` does not exist yet, skip the startup audit and continue with empty learn context.
   - If `learn_index.md` exists, run `python3 ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py check` before reading any learn entry.
   - If the home-path script is unavailable in a repository context, resolve the repository root and run `python3 home/dot_config/exact_agents/skills/worklog-manager/scripts/codex_worklog_audit.py check`.
   - If `check` fails, stop startup and report the exact audit failures to the parent. Do not continue with best-effort learn selection.
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

## Conflict Handling

Use this flow only when a later user direction conflicts with the current session facts.
For this workflow, `startup facts` means only the learn entries listed under the startup summary `Active learnings`.
`Needs revalidation`, `## Needs Review`, and any `active` learn with `freshness: drift_prone` are context only and are not `startup facts`.

The conflict detection scope is limited to:

- `startup facts`
- current plan `Assumptions`
- unfinished todo items

When a later user message conflicts with one of those sources:

1. Identify the exact source that is being contradicted.
2. Return `CONFLICT_REPORT` to the parent.
3. Wait for `CONFIRM_OVERRIDE`, `REJECT_OVERRIDE`, or `NEEDS_USER_CLARIFICATION`.
4. Rewrite session-local plan/todo state only after `CONFIRM_OVERRIDE`.
5. Do not update persistent learn state at this stage.
6. If you later record this session outcome in a learn file, use `Plan Updates` to note that it is a corpus migration candidate only after revalidation evidence exists.

The audit validates corpus integrity, not parent confirmation flow.

Use these parent-facing message contracts:

```text
CONFLICT_REPORT
source_type: startup_fact|plan_assumption|todo
source_ref: <learn filename | plan section | todo line>
old_statement: <current assumption>
user_request: <new direction>
rationale: <why this is a direction change instead of a minor refinement>
proposed_session_action: ignore_for_session|rewrite_plan_todo
learn_update: pending_revalidation
```

```text
CONFIRM_OVERRIDE
source_ref: <same value>
approved_action: rewrite_plan_todo
```

```text
REJECT_OVERRIDE
source_ref: <same value>
keep_existing_assumption: true
```

```text
NEEDS_USER_CLARIFICATION
source_ref: <same value>
clarification_question: <short question>
```

Do not write `.agents/worklog/codex/**` before confirmation.

After `CONFIRM_OVERRIDE`, rewrite `.agents/worklog/codex/**` with these rules:

- `User Prompt` update: append the user message that changed direction.
- `Assumptions` note: keep the old assumption, but annotate it with `Superseded in this session by user direction on YYYY-MM-DD`.
- `Design` update: add the new direction.
- `Open Questions` revalidation note: add one line when persistent learn revalidation is still needed.
- `TODO` rewrite: move unfinished items that depend on the old assumption to `# Done`, mark the individual line as superseded after the confirmed direction change, do not replace them with the literal line `[x] Superseded by confirmed direction change`, and add replacement work under `# TODO`.
- Keep top-level `todo.status` as `active` because the session is still in progress.

If the parent responds with `REJECT_OVERRIDE`, keep plan/todo unchanged and tell the parent `existing assumption kept`.
If the parent responds with `NEEDS_USER_CLARIFICATION`, keep plan/todo unchanged and wait for the parent's clarification flow.

## Learn Promotion Gate

- Do not promote session-local facts, current branch names, current paths, default-branch names, or any repo state that is cheap to re-check right now.
- Only store drift-prone repo state when repeated reuse has justified the cost. When you do, mark it `freshness: drift_prone` and set an explicit `review_after`.
- When you encounter legacy branch/default-branch learns, do targeted migration instead of broad corpus rewrites.
  - A fact like `default branch is master` must not stay `active`; move it to `superseded`.
  - A recipe that still assumes `origin/master` should move to `needs_review` until it is revalidated against the current `main` workflow.

## Audit

`check` is mandatory during startup whenever `learn_index.md` exists.
Use `summary` for manual inspection or for diagnosing a failed startup audit after the failure has already been reported to the parent.

```bash
python3 ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py check
python3 ~/.agents/skills/worklog-manager/scripts/codex_worklog_audit.py summary
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
