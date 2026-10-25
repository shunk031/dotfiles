#!/usr/bin/env bats

@test "[common] public apply keeps ~/.codex mode 700" {
    local home="${BATS_TEST_TMPDIR}/home"
    local apply_source="${BATS_TEST_TMPDIR}/apply-source"
    local public_codex_source="${PWD}/home/private_dot_codex"
    mkdir -p "${apply_source}"
    cp -R "${public_codex_source}" "${apply_source}/"
    mkdir -p "${home}/.codex"
    chmod 0755 "${home}/.codex"

    run chezmoi \
        --source "${apply_source}" \
        --destination "${home}" \
        --config /dev/null \
        --config-format toml \
        --cache "${BATS_TEST_TMPDIR}/cache" \
        --persistent-state "${BATS_TEST_TMPDIR}/state" \
        --refresh-externals=never \
        apply --force \
        --include=dirs \
        --exclude=externals,scripts \
        --recursive=false \
        "${home}/.codex"
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
