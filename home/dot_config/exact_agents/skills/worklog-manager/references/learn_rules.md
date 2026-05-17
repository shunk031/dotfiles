# Worklog Learn Rules

## Index Contract

`learn_index.md` is the startup authority for learn selection.
It must contain exactly these sections in this order:

1. `## Active`
2. `## Needs Review`
3. `## Superseded`
4. `## Archived`

Each entry stays on one line:

```text
- [Title](file.md) [stable|drift_prone] — Summary
```

The section determines the startup treatment:

- `Active`: eligible for startup reads.
- `Needs Review`: reference only, never a startup fact.
- `Superseded`: historical, skip unless migration/history is explicitly requested.
- `Archived`: historical, skip unless migration/history is explicitly requested.

## Startup Audit Gate

- If `learn_index.md` exists, startup must run `scripts/codex_worklog_audit.py check` before reading any learn entry.
- `check` must exit `0` before any `Active` entry can be treated as fact.
- If `check` fails, stop startup and return the exact audit failures to the parent instead of falling back to best-effort learn selection.
- `summary` is optional and is meant for diagnosis after a failure or for manual review.

## Frontmatter Rules

Every plan, todo, and learn file keeps the common keys:

- `type`
- `id`
- `owner`
- `created_at`
- `updated_at`

Learn files also require:

- `validated`
- `apply_to`
- `status`
- `freshness`
- `last_validated_at`

Additional rules:

- `status` is one of `active | needs_review | superseded | archived`
- `freshness` is one of `stable | drift_prone`
- `freshness: drift_prone` requires `review_after`
- `status: superseded` requires `superseded_by`
- Replacement learn files should add `supersedes`

## Learn Examples

### Active stable learn

```yaml
---
type: learn
id: learn-default-branch-main
owner: codex-main-worklog
created_at: 2026-05-15T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---
```

### Active drift-prone learn

```yaml
---
type: learn
id: learn-origin-main-recipe
owner: codex-main-worklog
created_at: 2026-05-15T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: drift_prone
last_validated_at: 2026-05-15T00:00:00Z
review_after: 2026-06-01T00:00:00Z
---
```

### Superseded learn

```yaml
---
type: learn
id: learn-default-branch-master
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: superseded
freshness: drift_prone
last_validated_at: 2026-05-15T00:00:00Z
superseded_by: default-branch-main.md
---
```

### Replacement learn

```yaml
---
type: learn
id: learn-default-branch-main
owner: codex-main-worklog
created_at: 2026-05-15T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
supersedes: default-branch-is-master.md
---
```

## Targeted Migration Rules

- Do not rewrite the entire corpus just to add new metadata.
- A fact like `default branch is master` must not stay `active`; move it to `Superseded` and point it at the current replacement learn.
- If an older recipe assumes `origin/master`, move it to `Needs Review` until it is revalidated on the current `main` workflow.
- Drift-prone repo state should stay out of `Active` unless it has a fresh validation date and a review deadline.

## Session-local override

- Session-local override is not a corpus migration.
- User direction alone must not move a learn entry to `needs_review` or `superseded`.
- A confirmed override still keeps persistent learn state unchanged until repo, system, or execution evidence exists.
- When a confirmed override plus revalidation evidence shows an `active` learn is obsolete, move it in the next corpus update to `needs_review` or `superseded`.
- Session-local overrides are governed by the conflict contract, not by audit.

```yaml
trigger: user asks for a different workflow than the startup fact assumes
immediate_action: session-local override only
persistent_action: defer until revalidation evidence exists
```

## Audit Contract

`scripts/codex_worklog_audit.py summary` reports:

- status counts from the index sections
- expired `review_after`
- active legacy metadata missing
- broken supersession links
- index/file mismatches

`scripts/codex_worklog_audit.py check` exits non-zero when startup would be unsafe, including:

- malformed or incomplete index sections
- active entries missing required new metadata
- active drift-prone entries with missing or expired `review_after`
- broken supersession links
- index/file mismatches
