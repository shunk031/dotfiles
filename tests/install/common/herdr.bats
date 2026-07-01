#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/herdr.sh"
readonly TMPL_SCRIPT_PATH="./home/.chezmoiscripts/common/run_once_after_03-install-herdr.sh.tmpl"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "${HOME}/.local/bin"

    source "${SCRIPT_PATH}"
}

function teardown() {
    PATH=$(getconf PATH)
    export PATH
}

@test "[common] herdr run-once template exists" {
    [ -f "${TMPL_SCRIPT_PATH}" ]
}

@test "[common] activate_mise evaluates mise activation output" {
    cat > "${MISE_BIN}" <<'EOF'
#!/usr/bin/env bash
if [ "$*" = "activate bash" ]; then
    printf '%s\n' 'export HERDR_TEST_MISE_ACTIVATED=1'
fi
EOF
    chmod +x "${MISE_BIN}"

    activate_mise

    [ "${HERDR_TEST_MISE_ACTIVATED}" = "1" ]
}

@test "[common] install_herdr_integrations installs configured integrations" {
    function herdr() {
        printf '%s\n' "$*" >> "${BATS_TEST_TMPDIR}/herdr_args.txt"
    }

    install_herdr_integrations

    run cat "${BATS_TEST_TMPDIR}/herdr_args.txt"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "integration install claude" ]
    [ "${lines[1]}" = "integration install codex" ]
}

@test "[common] install_herdr_skill installs the shared skill globally" {
    function npx() {
        printf '%s\n' "$*" > "${BATS_TEST_TMPDIR}/npx_args.txt"
    }

    install_herdr_skill

    run cat "${BATS_TEST_TMPDIR}/npx_args.txt"
    [ "${status}" -eq 0 ]
    [ "${output}" = "-y skills add ogulcancelik/herdr --skill herdr -g" ]
}
