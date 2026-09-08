#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/codex-plugins.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_05-install-codex-plugins.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
}

function teardown() {
    PATH=$(getconf PATH)
    export PATH
}

function write_mise_logger() {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
EOF
    chmod +x "${MISE_BIN}"
}

@test "[common] codex plugins run-once template includes the installer" {
    run cat "${TMPL_SCRIPT_PATH}"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{{ include "../install/common/codex-plugins.sh" }}' ]
}

@test "[common] activate_mise evaluates mise activation output" {
    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export CODEX_PLUGINS_TEST_MISE_ACTIVATED=1'
fi
EOF
    chmod +x "${MISE_BIN}"

    activate_mise

    [ "${CODEX_PLUGINS_TEST_MISE_ACTIVATED}" = "1" ]
}

@test "[common] install_ars_codex_plugin adds the marketplace before the plugin" {
    MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt"
    export MISE_CALLS_PATH
    write_mise_logger

    install_ars_codex_plugin

    run cat "${MISE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "exec -- codex plugin marketplace add Imbad0202/academic-research-skills-codex --ref main" ]
    [ "${lines[1]}" = "exec -- codex plugin add ars-codex@ars-codex" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "[common] codex plugins script runs the activated installation workflow" {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"

    cat > "${MISE_BIN}" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export CODEX_PLUGINS_TEST_MISE_ACTIVATED=1'
    printf '%s\n' "export PATH=\"${CODEX_PLUGINS_TEST_BIN}:${PATH}\""
fi
if [ "$1" = "exec" ]; then
    [ "${2:-}" = "--" ] || exit 1
    shift 2
    "$@"
fi
EOF
    chmod +x "${MISE_BIN}"

    cat > "${BATS_TEST_TMPDIR}/bin/codex" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "${CODEX_PLUGINS_TEST_MISE_ACTIVATED:-unset}|$*" >> "${CODEX_CALLS_PATH}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/codex"

    run env \
        CODEX_CALLS_PATH="${BATS_TEST_TMPDIR}/codex_args.txt" \
        CODEX_PLUGINS_TEST_BIN="${BATS_TEST_TMPDIR}/bin" \
        HOME="${HOME}" \
        MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise_args.txt" \
        bash "${SCRIPT_PATH}"
    [ "${status}" -eq 0 ]

    run cat "${BATS_TEST_TMPDIR}/mise_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "activate bash" ]
    [ "${lines[1]}" = "exec -- codex plugin marketplace add Imbad0202/academic-research-skills-codex --ref main" ]
    [ "${lines[2]}" = "exec -- codex plugin add ars-codex@ars-codex" ]
    [ "${#lines[@]}" -eq 3 ]

    run cat "${BATS_TEST_TMPDIR}/codex_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "1|plugin marketplace add Imbad0202/academic-research-skills-codex --ref main" ]
    [ "${lines[1]}" = "1|plugin add ars-codex@ars-codex" ]
    [ "${#lines[@]}" -eq 2 ]
}
