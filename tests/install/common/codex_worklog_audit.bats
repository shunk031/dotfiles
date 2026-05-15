#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_codex-worklog-audit"

function setup() {
    export LEARN_ROOT="${BATS_TEST_TMPDIR}/learn"
    mkdir -p "${LEARN_ROOT}"
}

function write_learn_file() {
    local filename="$1"
    local status="$2"
    local freshness="$3"
    local last_validated_at="$4"
    local review_after="$5"
    local superseded_by="$6"
    local supersedes="$7"

    {
        printf "%s\n" "---"
        printf "%s\n" "type: learn"
        printf "%s\n" "id: ${filename%_learn.md}"
        printf "%s\n" "owner: test"
        printf "%s\n" "created_at: 2026-05-14T00:00:00+09:00"
        printf "%s\n" "updated_at: 2026-05-14T00:00:00+09:00"
        printf "%s\n" "validated: true"
        printf "%s\n" "apply_to: []"

        if [ -n "${status}" ]; then
            printf "%s\n" "status: ${status}"
        fi

        if [ -n "${freshness}" ]; then
            printf "%s\n" "freshness: ${freshness}"
        fi

        if [ -n "${last_validated_at}" ]; then
            printf "%s\n" "last_validated_at: ${last_validated_at}"
        fi

        if [ -n "${review_after}" ]; then
            printf "%s\n" "review_after: ${review_after}"
        fi

        if [ -n "${superseded_by}" ]; then
            printf "%s\n" "superseded_by: ${superseded_by}"
        fi

        if [ -n "${supersedes}" ]; then
            printf "%s\n" "supersedes: ${supersedes}"
        fi

        printf "%s\n" "---"
        printf "\n# Date\n2026-05-14\n\n# Learnings\n- Fixture entry.\n\n# Plan Updates\n- None.\n"
    } > "${LEARN_ROOT}/${filename}"
}

function write_failing_fixture() {
    cat > "${LEARN_ROOT}/learn_index.md" <<'EOF'
# learn_index.md

## Active
- [Active stable](active_stable_learn.md) [stable] — Healthy active learn.
- [Active expired](active_expired_learn.md) [drift_prone] — Active drift-prone learn whose deadline passed.
- [Active legacy](active_legacy_learn.md) [stable] — Active entry without the new metadata.
- [Missing from disk](missing_from_disk_learn.md) [stable] — Index entry pointing to a missing file.

## Needs Review
- [drift_prone] [Needs review](needs_review_learn.md) — Reference-only learn pending revalidation.

## Superseded
- [Superseded](superseded_learn.md) [drift_prone] — Historical learn replaced by another file.

## Archived
- [Archived](archived_learn.md) [stable] — Archived learn kept only for history.
EOF

    write_learn_file "active_stable_learn.md" "active" "stable" "2026-05-14" "" "" ""
    write_learn_file "active_expired_learn.md" "active" "drift_prone" "2026-04-01" "2026-04-15" "" ""
    write_learn_file "active_legacy_learn.md" "" "" "" "" "" ""
    write_learn_file "needs_review_learn.md" "needs_review" "drift_prone" "2026-04-01" "2026-04-15" "" ""
    write_learn_file "superseded_learn.md" "superseded" "drift_prone" "2026-04-01" "2026-04-15" "missing_replacement_learn.md" ""
    write_learn_file "archived_learn.md" "archived" "stable" "2026-03-20" "" "" ""
    write_learn_file "orphan_learn.md" "needs_review" "stable" "2026-05-14" "" "" ""
}

function write_healthy_fixture() {
    cat > "${LEARN_ROOT}/learn_index.md" <<'EOF'
# learn_index.md

## Active
- [Active stable](active_stable_learn.md) [stable] — Healthy active learn.
- [Active drift-prone](active_drift_prone_learn.md) [drift_prone] — Active learn with a future review date.
- [stable] [Replacement](replacement_learn.md) — Active learn that supersedes the historical entry.

## Needs Review
- [Needs review](needs_review_learn.md) [drift_prone] — Reference-only learn pending revalidation.

## Superseded
- [Superseded](superseded_learn.md) [drift_prone] — Historical learn linked to its replacement.

## Archived
- [Archived](archived_learn.md) [stable] — Archived learn kept only for history.
EOF

    write_learn_file "active_stable_learn.md" "active" "stable" "2026-05-14" "" "" ""
    write_learn_file "active_drift_prone_learn.md" "active" "drift_prone" "2026-05-14" "2026-06-14" "" ""
    write_learn_file "replacement_learn.md" "active" "stable" "2026-05-14" "" "" "superseded_learn.md"
    write_learn_file "needs_review_learn.md" "needs_review" "drift_prone" "2026-05-14" "2026-06-14" "" ""
    write_learn_file "superseded_learn.md" "superseded" "drift_prone" "2026-05-14" "2026-06-14" "replacement_learn.md" ""
    write_learn_file "archived_learn.md" "archived" "stable" "2026-05-14" "" "" ""
}

@test "[common] codex-worklog-audit summary reports counts and stale learn findings" {
    write_failing_fixture

    run env CODEX_WORKLOG_LEARN_ROOT="${LEARN_ROOT}" bash "${SCRIPT_PATH}" summary
    [ "${status}" -eq 0 ]

    [[ "${output}" == *"Status counts:"* ]]
    [[ "${output}" == *"- active: 4"* ]]
    [[ "${output}" == *"- needs_review: 1"* ]]
    [[ "${output}" == *"- superseded: 1"* ]]
    [[ "${output}" == *"- archived: 1"* ]]
    [[ "${output}" == *"- active_expired_learn.md (active, review_after=2026-04-15)"* ]]
    [[ "${output}" == *"- active_legacy_learn.md (status, freshness, last_validated_at)"* ]]
    [[ "${output}" == *"- superseded_learn.md (superseded_by=missing_replacement_learn.md)"* ]]
    [[ "${output}" == *"- indexed file missing on disk: missing_from_disk_learn.md"* ]]
    [[ "${output}" == *"- file missing from index: orphan_learn.md"* ]]
}

@test "[common] codex-worklog-audit check fails on startup-breaking learn states" {
    write_failing_fixture

    run env CODEX_WORKLOG_LEARN_ROOT="${LEARN_ROOT}" bash "${SCRIPT_PATH}" check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"check: FAIL"* ]]
    [[ "${output}" == *"- active_expired_learn.md (active, review_after=2026-04-15)"* ]]
    [[ "${output}" == *"- active_legacy_learn.md (status, freshness, last_validated_at)"* ]]
}

@test "[common] codex-worklog-audit check passes for a healthy learn corpus" {
    write_healthy_fixture

    run env CODEX_WORKLOG_LEARN_ROOT="${LEARN_ROOT}" bash "${SCRIPT_PATH}" check
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"check: OK"* ]]
    [[ "${output}" == *"Active entries missing required metadata:\nnone"* || "${output}" == *$'Active entries missing required metadata:\nnone'* ]]
    [[ "${output}" == *"Broken supersession links:\nnone"* || "${output}" == *$'Broken supersession links:\nnone'* ]]
    [[ "${output}" == *"Index mismatches:\nnone"* || "${output}" == *$'Index mismatches:\nnone'* ]]
}
