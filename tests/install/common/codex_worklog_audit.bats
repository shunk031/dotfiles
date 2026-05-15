#!/usr/bin/env bats

readonly SCRIPT_PATH="./home/dot_local/bin/exact_common/executable_codex-worklog-audit"

function setup() {
    export LEARN_ROOT="${BATS_TEST_TMPDIR}/learn"
    mkdir -p "${LEARN_ROOT}"
}

function write_learn_file() {
    local filename="$1"
    local learn_status="$2"
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

        if [ -n "${learn_status}" ]; then
            printf "%s\n" "status: ${learn_status}"
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
    cat > "${LEARN_ROOT}/learn_index.md" << 'EOF'
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
    cat > "${LEARN_ROOT}/learn_index.md" << 'EOF'
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

function write_edge_case_fixture() {
    cat > "${LEARN_ROOT}/learn_index.md" << 'EOF'
# learn_index.md

## Future Ideas
- [Ignored future learn](ignored_future_learn.md) [stable] — Unknown sections must stay out of the audit.

## Active
- [Missing review_after](active_missing_review_after_learn.md) [drift_prone] — Drift-prone active learn missing review_after.
- [Status mismatch](status_mismatch_learn.md) [stable] — File metadata disagrees with the index section.
- [Replacement without reciprocal](replacement_without_supersedes_learn.md) [stable] — Replacement learn missing reciprocal supersedes.
- [Missing supersedes target](supersedes_missing_target_learn.md) [stable] — Learn points to a missing superseded file.

## Superseded
- [Missing replacement](superseded_missing_replacement_learn.md) [stable] — Superseded learn missing superseded_by.
- [Needs reciprocal supersedes](superseded_nonreciprocal_learn.md) [stable] — Replacement exists but omits supersedes.
EOF

    write_learn_file "active_missing_review_after_learn.md" "active" "drift_prone" "2026-05-14" "" "" ""
    write_learn_file "status_mismatch_learn.md" "needs_review" "stable" "2026-05-14" "" "" ""
    write_learn_file "replacement_without_supersedes_learn.md" "active" "stable" "2026-05-14" "" "" ""
    write_learn_file "supersedes_missing_target_learn.md" "active" "stable" "2026-05-14" "" "" "missing_target_learn.md"
    write_learn_file "superseded_missing_replacement_learn.md" "superseded" "stable" "2026-05-14" "" "" ""
    write_learn_file "superseded_nonreciprocal_learn.md" "superseded" "stable" "2026-05-14" "" "replacement_without_supersedes_learn.md" ""
}

function write_mock_chezmoi() {
    local source_path="$1"
    local mock_bin="${BATS_TEST_TMPDIR}/bin"

    mkdir -p "${mock_bin}"

    cat > "${mock_bin}/chezmoi" << EOF
#!/usr/bin/env bash

if [ "\${1:-}" = "source-path" ]; then
    printf "%s\n" "${source_path}"
    exit 0
fi

printf "unsupported chezmoi subcommand: %s\n" "\${1:-}" >&2
exit 1
EOF

    chmod +x "${mock_bin}/chezmoi"
    printf "%s\n" "${mock_bin}"
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

@test "[common] codex-worklog-audit summary reports review, supersession, and status edge cases" {
    write_edge_case_fixture

    run env CODEX_WORKLOG_LEARN_ROOT="${LEARN_ROOT}" bash "${SCRIPT_PATH}" summary
    [ "${status}" -eq 0 ]

    [[ "${output}" == *"- active: 4"* ]]
    [[ "${output}" == *"- superseded: 2"* ]]
    [[ "${output}" == *"- active_missing_review_after_learn.md (review_after)"* ]]
    [[ "${output}" == *"- superseded_missing_replacement_learn.md (missing superseded_by)"* ]]
    [[ "${output}" == *"- superseded_nonreciprocal_learn.md (replacement replacement_without_supersedes_learn.md is missing reciprocal supersedes)"* ]]
    [[ "${output}" == *"- supersedes_missing_target_learn.md (supersedes=missing_target_learn.md)"* ]]
    [[ "${output}" == *"- status mismatch: status_mismatch_learn.md (index=active, file=needs_review)"* ]]
    [[ "${output}" != *"ignored_future_learn.md"* ]]
}

@test "[common] codex-worklog-audit resolves the learn root through chezmoi source-path" {
    local source_root="${BATS_TEST_TMPDIR}/chezmoi-source"
    local mock_bin

    export LEARN_ROOT="${source_root}/.agents/worklog/codex/learn"
    mkdir -p "${LEARN_ROOT}"
    write_healthy_fixture
    mock_bin="$(write_mock_chezmoi "${source_root}")"

    run env -u CODEX_WORKLOG_LEARN_ROOT PATH="${mock_bin}:${PATH}" bash "${SCRIPT_PATH}" check
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"check: OK"* ]]
}

@test "[common] codex-worklog-audit fails when the learn root path is missing" {
    local missing_root="${BATS_TEST_TMPDIR}/missing-learn-root"

    run env CODEX_WORKLOG_LEARN_ROOT="${missing_root}" bash "${SCRIPT_PATH}" summary
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"learn root not found: ${missing_root}"* ]]
}

@test "[common] codex-worklog-audit fails when the learn index is missing" {
    local indexless_root="${BATS_TEST_TMPDIR}/indexless-root"

    mkdir -p "${indexless_root}"

    run env CODEX_WORKLOG_LEARN_ROOT="${indexless_root}" bash "${SCRIPT_PATH}" check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"learn index not found: ${indexless_root}/learn_index.md"* ]]
}

@test "[common] codex-worklog-audit errors when chezmoi is unavailable and no learn root is set" {
    run env -u CODEX_WORKLOG_LEARN_ROOT PATH="/usr/bin:/bin" bash "${SCRIPT_PATH}" summary
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"chezmoi is required unless CODEX_WORKLOG_LEARN_ROOT is set"* ]]
}

@test "[common] codex-worklog-audit rejects unsupported commands" {
    write_healthy_fixture

    run env CODEX_WORKLOG_LEARN_ROOT="${LEARN_ROOT}" bash "${SCRIPT_PATH}" unsupported
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"usage: executable_codex-worklog-audit {summary|check}"* ]]
}
