#!/usr/bin/env bats

@test "[common] public apply keeps ~/.codex mode 700" {
    local home="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${home}/.codex"
    chmod 0755 "${home}/.codex"

    run chezmoi \
        --source "${PWD}" \
        --destination "${home}" \
        --config /dev/null \
        --config-format toml \
        --cache "${BATS_TEST_TMPDIR}/cache" \
        --persistent-state "${BATS_TEST_TMPDIR}/state" \
        apply --force --include=dirs --recursive=false "${home}/.codex"
    [ "${status}" -eq 0 ]

    run python3 -c '
import os
import stat
import sys

st = os.lstat(sys.argv[1])
assert stat.S_ISDIR(st.st_mode)
assert stat.S_IMODE(st.st_mode) == 0o700
' "${home}/.codex"
    [ "${status}" -eq 0 ]
}
