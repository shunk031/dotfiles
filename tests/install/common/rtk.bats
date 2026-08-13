#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/rtk.sh"
readonly TEMPLATE_PATH="./home/.chezmoiscripts/common/run_after_30-install-rtk.sh.tmpl"
readonly TEMPLATE_PATH="./home/.chezmoiscripts/common/run_after_30-install-rtk.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}"
    source "${SCRIPT_PATH}"
}

@test "[common] initialize_rtk uses the supported global init modes" {
    local calls_path="${BATS_TEST_TMPDIR}/rtk_calls.txt"

    rtk() {
        printf '%s|telemetry=%s\n' "$*" "${RTK_TELEMETRY_DISABLED:-}" >> "${calls_path}"
    }

    initialize_rtk

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'init -g --auto-patch|telemetry=1\ninit -g --gemini --auto-patch|telemetry=1' ]
}

@test "[common] run-after template includes the standalone installer" {
    run cat "${TEMPLATE_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{{ include "../install/common/rtk.sh" }}' ]
}
