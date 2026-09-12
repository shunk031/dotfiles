#!/usr/bin/env bats

# @file tests/install/common/run_unit_test.bats
# @brief Verify explicit target dispatch failures.
# @description
#   Confirms unsupported targets fail before any real Bats suite is executed.

bats_require_minimum_version 1.5.0

readonly SCRIPT_PATH="./scripts/run_unit_test.sh"

@test "[common] run_unit_test rejects an unsupported target" {
    local stub_bin="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "${stub_bin}"

    cat > "${stub_bin}/bats" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "${stub_bin}/bats"

    run --separate-stderr env \
        PATH="${stub_bin}:${PATH}" \
        TARGET_OS=unsupported \
        SYSTEM=server \
        bash "${SCRIPT_PATH}"

    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    [[ "${stderr}" == *"unsupported and server are not supported"* ]]
}
