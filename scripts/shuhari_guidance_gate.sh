#!/usr/bin/env bash

# @file scripts/shuhari_guidance_gate.sh
# @brief Run the shared guidance gate with this repository's pinned policy.
# @description
#   The two guidance hooks and `make eval-guidance` used to carry their own
#   copy of the same Shuhari invocation, with every flag written inline. That
#   left no place to describe the machine a run happens on, so a host whose
#   kernel refuses Shuhari's default isolated sandbox could not run the gate at
#   all, and a guidance edit there could only be committed by skipping it.
#
#   This wrapper owns target selection and policy; Shuhari owns the evaluation
#   mechanism, per the Shuhari development architecture contract.
#
#   The execution environment can be adjusted with `SHUHARI_SANDBOX` and
#   `SHUHARI_AGENT_EXECUTABLE`. Each adds its corresponding flag, and an
#   `unsandboxed` sandbox also adds `--network`, as Shuhari requires. Leaving
#   both unset preserves the argv the inline entries used byte for byte.
#
#   Schema validation is exempt from both. It parses files, starts no agent and
#   enters no sandbox, and Shuhari reads `SHUHARI_SANDBOX` from the environment
#   on its own, so an exported `unsandboxed` would fail a `--validate-only` run
#   over an execution environment that run never establishes.
#
#   These are environment-shaped overrides only. Trials, jobs, and the timeout
#   define measurement and remain pinned below; they are not overridable.
# @arg $1 mode One of `validate` or `eval`.
# @exitcode 0 The gate passed.
# @exitcode 1 The gate failed.
# @exitcode 2 Invalid usage.
# @example
#   scripts/shuhari_guidance_gate.sh validate
#   SHUHARI_SANDBOX=unsandboxed scripts/shuhari_guidance_gate.sh eval

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

# Repository-relative so the argv stays readable in hook output and identical
# on every machine.
readonly MISE_CONFIG="home/dot_mise/config.toml"
readonly GUIDANCE="home/dot_config/exact_agents/AGENTS.md"
readonly GUIDANCE_EVALS="home/dot_config/exact_agents/AGENTS.evals.json"

# Policy values owned by this repository rather than by Shuhari. Two arms per
# case at three trials is what makes a guidance verdict trustworthy, so these
# stay out of reach of the environment.
readonly TRIALS=3
readonly JOBS=2
readonly TIMEOUT=600

# @description Read lines from standard input into a named array.
# @description
#   `mapfile` is Bash 4 only, and macOS ships Bash 3.2. This keeps the script
#   runnable with the system shell.
# @arg $1 array_name The array to replace with the lines read.
function read_lines_into() {
    local array_name="$1"
    local line
    eval "${array_name}=()"
    while IFS= read -r line; do
        [ -n "${line}" ] || continue
        eval "${array_name}+=(\"\${line}\")"
    done
}

# @description Print flags for execution-environment overrides.
# @stdout Alternating flag names and values, with `--network` for an
#   `unsandboxed` sandbox.
function declared_environment_flags() {
    if [ -n "${SHUHARI_SANDBOX:-}" ]; then
        printf -- '--sandbox\n%s\n' "${SHUHARI_SANDBOX}"
        if [ "${SHUHARI_SANDBOX}" = unsandboxed ]; then
            printf '%s\n' '--network'
        fi
    fi

    if [ -n "${SHUHARI_AGENT_EXECUTABLE:-}" ]; then
        printf -- '--agent-executable\n%s\n' "${SHUHARI_AGENT_EXECUTABLE}"
    fi
}

# @description Validate the guidance eval schema without invoking an agent.
# @description
#   Stripped of the execution-environment variables Shuhari reads directly, for
#   the reason given in this file's description.
# @exitcode 1 When the schema is invalid.
function run_validate() {
    env -u SHUHARI_SANDBOX -u SHUHARI_I_UNDERSTAND_NO_CREDENTIAL_BOUNDARY \
        MISE_CONFIG_FILE="${MISE_CONFIG}" mise exec -- \
        shuhari eval instructions "${GUIDANCE}" \
        --evals "${GUIDANCE_EVALS}" \
        --validate-only
}

# @description Evaluate the shared guidance with and without the instructions.
# @exitcode 1 When the evaluation fails.
function run_eval() {
    local -a environment_flags=()
    read_lines_into environment_flags < <(declared_environment_flags)

    # Bash 3.2 treats expanding an empty array as an unbound variable under
    # `set -u`, so the expansion is guarded.
    MISE_CONFIG_FILE="${MISE_CONFIG}" mise exec -- \
        shuhari eval instructions "${GUIDANCE}" \
        --evals "${GUIDANCE_EVALS}" \
        ${environment_flags[@]+"${environment_flags[@]}"} \
        --trials "${TRIALS}" --jobs "${JOBS}" --timeout "${TIMEOUT}"
}

# @description Dispatch the requested gate.
# @arg $1 mode One of `validate` or `eval`.
function main() {
    local mode="${1:-}"

    case "${mode}" in
    validate | eval) ;;
    *)
        printf 'Usage: %s {validate|eval}\n' "$0" >&2
        exit 2
        ;;
    esac

    # Every path above is repository-relative, including the one mise resolves
    # its configuration from.
    cd -- "${REPO_ROOT}"
    "run_${mode}"
}

main "$@"
