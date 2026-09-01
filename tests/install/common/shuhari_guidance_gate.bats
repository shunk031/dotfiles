#!/usr/bin/env bats

# The wrapper reaches Shuhari through `mise exec`, so these tests answer that
# call with a stub that records the argv it was handed and the two
# execution-environment variables Shuhari would otherwise read on its own.
# Nothing here starts an agent or makes a model call.

readonly WRAPPER="./scripts/shuhari_guidance_gate.sh"
readonly GUIDANCE="home/dot_config/exact_agents/AGENTS.md"
readonly GUIDANCE_EVALS="home/dot_config/exact_agents/AGENTS.evals.json"

setup() {
    local stub_bin="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "${stub_bin}"

    SHUHARI_ARGV_LOG="${BATS_TEST_TMPDIR}/shuhari-argv"
    SHUHARI_ENV_LOG="${BATS_TEST_TMPDIR}/shuhari-env"
    export SHUHARI_ARGV_LOG SHUHARI_ENV_LOG

    cat > "${stub_bin}/mise" << 'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--" ]; then
    shift 2
    printf '%s\n' "$@" > "${SHUHARI_ARGV_LOG}"
    {
        printf 'MISE_CONFIG_FILE=%s\n' "${MISE_CONFIG_FILE-<unset>}"
        printf 'SHUHARI_SANDBOX=%s\n' "${SHUHARI_SANDBOX-<unset>}"
        printf 'SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY=%s\n' \
            "${SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY-<unset>}"
    } > "${SHUHARI_ENV_LOG}"
    exit 0
fi
exit 1
EOF
    chmod +x "${stub_bin}/mise"
    PATH="${stub_bin}:${PATH}"
    export PATH
}

# @description Run the wrapper with every override variable removed.
function run_without_overrides() {
    run env -u SHUHARI_SANDBOX -u SHUHARI_AGENT_EXECUTABLE \
        -u SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY "${WRAPPER}" "$@"
}

@test "[common] guidance gate wrapper is executable" {
    [ -x "${WRAPPER}" ]
}

@test "[common] unset overrides preserve the eval argv" {
    local expected="${BATS_TEST_TMPDIR}/expected"
    printf '%s\n' \
        shuhari \
        eval \
        instructions \
        "${GUIDANCE}" \
        --evals \
        "${GUIDANCE_EVALS}" \
        --trials \
        3 \
        --jobs \
        2 \
        --timeout \
        600 > "${expected}"

    run_without_overrides eval
    [ "${status}" -eq 0 ]

    run diff -u "${expected}" "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
}

@test "[common] unset overrides preserve the validate argv" {
    local expected="${BATS_TEST_TMPDIR}/expected"
    printf '%s\n' \
        shuhari \
        eval \
        instructions \
        "${GUIDANCE}" \
        --evals \
        "${GUIDANCE_EVALS}" \
        --validate-only > "${expected}"

    run_without_overrides validate
    [ "${status}" -eq 0 ]

    run diff -u "${expected}" "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
}

@test "[common] both modes pin the mise configuration file" {
    run_without_overrides validate
    [ "${status}" -eq 0 ]
    run grep -Fx 'MISE_CONFIG_FILE=home/dot_mise/config.toml' "${SHUHARI_ENV_LOG}"
    [ "${status}" -eq 0 ]

    run_without_overrides eval
    [ "${status}" -eq 0 ]
    run grep -Fx 'MISE_CONFIG_FILE=home/dot_mise/config.toml' "${SHUHARI_ENV_LOG}"
    [ "${status}" -eq 0 ]
}

@test "[common] an unsandboxed sandbox adds the network flag" {
    run env SHUHARI_SANDBOX=unsandboxed "${WRAPPER}" eval
    [ "${status}" -eq 0 ]

    run grep -cFx -- '--sandbox' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
    run grep -cFx -- 'unsandboxed' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
    run grep -cFx -- '--network' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
}

@test "[common] a sandboxed level is passed through without the network flag" {
    run env SHUHARI_SANDBOX=read-only "${WRAPPER}" eval
    [ "${status}" -eq 0 ]

    run grep -cFx -- 'read-only' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
    run grep -Fx -- '--network' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -ne 0 ]
}

@test "[common] an agent executable override reaches the eval run" {
    run env SHUHARI_AGENT_EXECUTABLE=/usr/local/bin/codex-wrapper \
        "${WRAPPER}" eval
    [ "${status}" -eq 0 ]

    run grep -cFx -- '--agent-executable' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
    run grep -cFx -- '/usr/local/bin/codex-wrapper' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -eq 0 ]
    [ "${output}" -eq 1 ]
}

@test "[common] validation is exempt from execution-environment overrides" {
    # Schema validation starts no agent and enters no sandbox, and Shuhari
    # reads these two variables from the environment itself, so an exported
    # `unsandboxed` would fail an offline parse over a sandbox it never enters.
    run env SHUHARI_SANDBOX=unsandboxed \
        SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY=1 \
        SHUHARI_AGENT_EXECUTABLE=/usr/local/bin/codex-wrapper \
        "${WRAPPER}" validate
    [ "${status}" -eq 0 ]

    run grep -Fx 'SHUHARI_SANDBOX=<unset>' "${SHUHARI_ENV_LOG}"
    [ "${status}" -eq 0 ]
    run grep -Fx 'SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY=<unset>' \
        "${SHUHARI_ENV_LOG}"
    [ "${status}" -eq 0 ]

    run grep -Fx -- '--sandbox' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -ne 0 ]
    run grep -Fx -- '--agent-executable' "${SHUHARI_ARGV_LOG}"
    [ "${status}" -ne 0 ]
}

@test "[common] the eval run keeps the sandbox variable Shuhari reads" {
    # The exemption is scoped to validation. An eval run has an execution
    # environment, so Shuhari must still see what it was told to use.
    run env SHUHARI_SANDBOX=unsandboxed "${WRAPPER}" eval
    [ "${status}" -eq 0 ]

    run grep -Fx 'SHUHARI_SANDBOX=unsandboxed' "${SHUHARI_ENV_LOG}"
    [ "${status}" -eq 0 ]
}

@test "[common] an unknown mode fails with usage" {
    run "${WRAPPER}" trigger
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Usage:"* ]]

    run "${WRAPPER}"
    [ "${status}" -eq 2 ]
}
