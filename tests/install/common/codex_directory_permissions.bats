#!/usr/bin/env bats

@test "[common] public and private apply order keeps ~/.codex mode 700" {
    local home="${BATS_TEST_TMPDIR}/home"
    local public_source="${BATS_TEST_TMPDIR}/public-source"
    local private_source="${BATS_TEST_TMPDIR}/private-source"
    local source_name apply_source
    local public_codex_source="${PWD}/home/private_dot_codex"
    mkdir -p "${public_source}" "${private_source}/private_dot_codex"
    cp -R "${public_codex_source}" "${public_source}/"
    printf 'fixture = true\n' > "${private_source}/private_dot_codex/private_config.toml"
    mkdir -p "${home}/.codex"
    chmod 0755 "${home}/.codex"

    for source_name in public private public; do
        if [[ "${source_name}" == public ]]; then
            apply_source="${public_source}"
        else
            apply_source="${private_source}"
        fi

        run chezmoi \
            --source "${apply_source}" \
            --destination "${home}" \
            --config /dev/null \
            --config-format toml \
            --cache "${BATS_TEST_TMPDIR}/cache-${source_name}" \
            --persistent-state "${BATS_TEST_TMPDIR}/state-${source_name}" \
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
    done
}
