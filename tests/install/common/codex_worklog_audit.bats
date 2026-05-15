#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_config/exact_agents/skills/worklog-manager/scripts/codex_worklog_audit.py"
readonly FIXED_NOW="2026-05-15T00:00:00Z"

function setup() {
    export LEARN_ROOT="${BATS_TEST_TMPDIR}/learn"
    mkdir -p "${LEARN_ROOT}"
}

function write_file() {
    local target="$1"

    mkdir -p "$(dirname "${target}")"
    cat > "${target}"
}

function write_clean_fixture() {
    write_file "${LEARN_ROOT}/learn_index.md" << 'EOF'
## Active
- [Repo layout](repo-layout.md) [stable] — Stable repo layout guidance.
- [Default branch is main](default-branch-main.md) [stable] — Current default branch fact.

## Needs Review
- [Origin main recipe](origin-main-recipe.md) [drift_prone] — Revalidate this recipe before reuse.

## Superseded
- [Default branch is master](default-branch-is-master.md) [drift_prone] — Historical branch fact.

## Archived
- [Migration notes](migration-notes.md) [stable] — Historical migration notes.
EOF

    write_file "${LEARN_ROOT}/repo-layout.md" << 'EOF'
---
type: learn
id: learn-repo-layout
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/default-branch-main.md" << 'EOF'
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

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/origin-main-recipe.md" << 'EOF'
---
type: learn
id: learn-origin-main-recipe
owner: codex-main-worklog
created_at: 2026-05-10T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: needs_review
freshness: drift_prone
last_validated_at: 2026-05-15T00:00:00Z
review_after: 2099-01-01T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/default-branch-is-master.md" << 'EOF'
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

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/migration-notes.md" << 'EOF'
---
type: learn
id: learn-migration-notes
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: archived
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---

# Date

2026-05-15
EOF
}

function write_mixed_fixture() {
    write_file "${LEARN_ROOT}/learn_index.md" << 'EOF'
## Active
- [Default branch is main](default-branch-main.md) [stable] — Current default branch fact.
- [Legacy branch note](legacy-branch-note.md) [stable] — Active legacy entry without new metadata.
- [Origin main recipe](origin-main-recipe.md) [drift_prone] — Active drift-prone recipe that is overdue.
- [Ghost entry](ghost-entry.md) [stable] — Indexed but missing on disk.

## Needs Review
- [Origin master recipe](origin-master-recipe.md) [drift_prone] — Historical recipe pending revalidation.

## Superseded
- [Default branch is master](default-branch-is-master.md) [drift_prone] — Historical branch fact.
- [Broken master note](broken-master-note.md) [stable] — Superseded learn without a replacement.

## Archived
- [Migration notes](migration-notes.md) [stable] — Historical migration notes.
EOF

    write_file "${LEARN_ROOT}/default-branch-main.md" << 'EOF'
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

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/legacy-branch-note.md" << 'EOF'
---
type: learn
id: learn-legacy-branch-note
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/origin-main-recipe.md" << 'EOF'
---
type: learn
id: learn-origin-main-recipe
owner: codex-main-worklog
created_at: 2026-05-10T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: drift_prone
last_validated_at: 2026-05-10T00:00:00Z
review_after: 2026-05-10T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/origin-master-recipe.md" << 'EOF'
---
type: learn
id: learn-origin-master-recipe
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: needs_review
freshness: drift_prone
last_validated_at: 2026-05-15T00:00:00Z
review_after: 2099-01-01T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/default-branch-is-master.md" << 'EOF'
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

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/broken-master-note.md" << 'EOF'
---
type: learn
id: learn-broken-master-note
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: superseded
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/migration-notes.md" << 'EOF'
---
type: learn
id: learn-migration-notes
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: archived
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---

# Date

2026-05-15
EOF

    write_file "${LEARN_ROOT}/stray-note.md" << 'EOF'
---
type: learn
id: learn-stray-note
owner: codex-main-worklog
created_at: 2026-05-01T00:00:00Z
updated_at: 2026-05-15T00:00:00Z
validated: true
apply_to:
  - codex
status: active
freshness: stable
last_validated_at: 2026-05-15T00:00:00Z
---

# Date

2026-05-15
EOF
}

@test "[common] codex_worklog_audit summary reports stale-learn findings deterministically" {
    write_mixed_fixture

    run python3 "${SCRIPT_PATH}" summary --learn-root "${LEARN_ROOT}" --now "${FIXED_NOW}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"active: 4"* ]]
    [[ "${output}" == *"needs_review: 1"* ]]
    [[ "${output}" == *"superseded: 2"* ]]
    [[ "${output}" == *"archived: 1"* ]]
    [[ "${output}" == *"origin-main-recipe.md (status=active review_after=2026-05-10T00:00:00Z)"* ]]
    [[ "${output}" == *"legacy-branch-note.md -> missing status, freshness, last_validated_at"* ]]
    [[ "${output}" == *"broken-master-note.md -> missing superseded_by"* ]]
    [[ "${output}" == *"indexed file missing: ghost-entry.md"* ]]
    [[ "${output}" == *"unindexed learn file: stray-note.md"* ]]
}

@test "[common] codex_worklog_audit check fails on startup-breaking stale-learn state" {
    write_mixed_fixture

    run python3 "${SCRIPT_PATH}" check --learn-root "${LEARN_ROOT}" --now "${FIXED_NOW}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: startup-breaking worklog learn issues found."* ]]
    [[ "${output}" == *"active entry missing metadata: legacy-branch-note.md -> missing status, freshness, last_validated_at"* ]]
    [[ "${output}" == *"expired active review_after: origin-main-recipe.md (status=active review_after=2026-05-10T00:00:00Z)"* ]]
    [[ "${output}" == *"broken supersession link: broken-master-note.md -> missing superseded_by"* ]]
    [[ "${output}" == *"index/file mismatch: indexed file missing: ghost-entry.md"* ]]
    [[ "${output}" == *"index/file mismatch: unindexed learn file: stray-note.md"* ]]
}

@test "[common] codex_worklog_audit check passes for a clean gated corpus" {
    write_clean_fixture

    run python3 "${SCRIPT_PATH}" check --learn-root "${LEARN_ROOT}" --now "${FIXED_NOW}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "OK: no startup-breaking worklog learn issues found." ]
}
