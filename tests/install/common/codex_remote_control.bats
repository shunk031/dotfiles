#!/usr/bin/env bats

# @file tests/install/common/codex_remote_control.bats
# @brief Cover the Codex remote-control bootstrap with offline dependency stubs.
# @description
#   Executes the production script with isolated HOME state and local mise,
#   curl, and installer stubs.

readonly SCRIPT_PATH="${BATS_TEST_DIRNAME}/../../../install/common/codex-remote-control.sh"

function setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    export CODEX_REMOTE_CONTROL_ENABLED=1
    export MISE_VERSION=0.157.1
    export MISE_CALLS_PATH="${BATS_TEST_TMPDIR}/mise-calls"
    export CURL_CALLS_PATH="${BATS_TEST_TMPDIR}/curl-calls"
    export CURL_OUTPUT_PATH="${BATS_TEST_TMPDIR}/curl-output"
    export INSTALLER_SOURCE_PATH="${BATS_TEST_TMPDIR}/installer.sh"
    export INSTALLER_RELEASE_PATH="${BATS_TEST_TMPDIR}/installer-release"
    unset CODEX_HOME DOTFILES_DEBUG

    mkdir -p "${HOME}/.local/bin" "${BATS_TEST_TMPDIR}/bin"
    : > "${MISE_CALLS_PATH}"
    : > "${CURL_CALLS_PATH}"

    cat > "${HOME}/.local/bin/mise" << 'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "${MISE_CALLS_PATH}"
if [ "$*" = 'exec -- codex --version' ]; then
    printf 'codex-cli %s\n' "${MISE_VERSION}"
fi
EOF
    chmod +x "${HOME}/.local/bin/mise"

    cat > "${BATS_TEST_TMPDIR}/bin/curl" << 'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "${CURL_CALLS_PATH}"
while [ "$#" -gt 0 ]; do
    if [ "$1" = -o ]; then
        shift
        printf '%s\n' "$1" > "${CURL_OUTPUT_PATH}"
        cp "${INSTALLER_SOURCE_PATH}" "$1"
    fi
    shift
done
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/curl"

    cat > "${INSTALLER_SOURCE_PATH}" << 'EOF'
#!/bin/sh
set -eu
daemon="${CODEX_HOME}/packages/standalone/current/codex"
mkdir -p "$(dirname "${daemon}")" "${CODEX_INSTALL_DIR}" "${HOME}/.local/bin"
printf '%s\n' "${CODEX_RELEASE}" > "${INSTALLER_RELEASE_PATH}"
cat > "${daemon}" <<DAEMON
#!/bin/sh
printf 'codex-cli %s\\n' '${CODEX_RELEASE}'
DAEMON
chmod +x "${daemon}"
ln -s "${daemon}" "${CODEX_INSTALL_DIR}/codex"
ln -s "${INSTALLER_USER_ALIAS:-${daemon}}" "${HOME}/.local/bin/codex"
exit "${INSTALLER_EXIT_CODE:-0}"
EOF
    chmod +x "${INSTALLER_SOURCE_PATH}"

    PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
    export PATH
}

# @description Write a standalone daemon that reports the requested version.
# @arg $1 version Semantic version to report.
function write_installed_daemon() {
    local version="$1"
    local daemon="${HOME}/.codex/packages/standalone/current/codex"

    mkdir -p "$(dirname "${daemon}")"
    cat > "${daemon}" << DAEMON
#!/bin/sh
printf 'codex-cli %s\\n' '${version}'
DAEMON
    chmod +x "${daemon}"
}

@test "[common] codex remote control skips all dependencies when disabled" {
    run env CODEX_REMOTE_CONTROL_ENABLED=0 bash "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ ! -s "${MISE_CALLS_PATH}" ]
    [ ! -s "${CURL_CALLS_PATH}" ]
    [ ! -e "${HOME}/.codex" ]
}

@test "[common] codex remote control reuses a matching standalone daemon" {
    local codex_home="${HOME}/.codex"
    local daemon="${codex_home}/packages/standalone/current/codex"

    write_installed_daemon "${MISE_VERSION}"
    mkdir -p "${codex_home}/daemon-bin"
    ln -s "${daemon}" "${codex_home}/daemon-bin/codex"
    ln -s "${daemon}" "${HOME}/.local/bin/codex"

    run bash "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ ! -e "${codex_home}/daemon-bin/codex" ]
    [ ! -e "${HOME}/.local/bin/codex" ]
    [ ! -s "${CURL_CALLS_PATH}" ]
    [ "$(wc -l < "${MISE_CALLS_PATH}")" -eq 3 ]
    grep -Fxq 'exec -- codex --version' "${MISE_CALLS_PATH}"
    grep -Fxq 'exec -- codex app-server daemon enable-remote-control' "${MISE_CALLS_PATH}"
    grep -Fxq 'exec -- codex app-server daemon start' "${MISE_CALLS_PATH}"
}

@test "[common] codex remote control installs the mise version when versions differ" {
    write_installed_daemon 0.156.0

    run bash "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ "$(cat "${INSTALLER_RELEASE_PATH}")" = "${MISE_VERSION}" ]
    run env -u BASH_ENV -u BASH_XTRACEFD -u SHELLOPTS -u PS4 \
        "${HOME}/.codex/packages/standalone/current/codex" --version
    [ "${status}" -eq 0 ]
    [ "${output}" = "codex-cli ${MISE_VERSION}" ]
    [[ "$(cat "${CURL_CALLS_PATH}")" == "-fsSL https://chatgpt.com/codex/install.sh -o "* ]]
    [ ! -e "${HOME}/.codex/daemon-bin/codex" ]
    [ ! -e "${HOME}/.local/bin/codex" ]
    [ "$(wc -l < "${MISE_CALLS_PATH}")" -eq 3 ]
    grep -Fxq 'exec -- codex --version' "${MISE_CALLS_PATH}"
    grep -Fxq 'exec -- codex app-server daemon enable-remote-control' "${MISE_CALLS_PATH}"
    grep -Fxq 'exec -- codex app-server daemon start' "${MISE_CALLS_PATH}"
}

@test "[common] codex remote control cleans failed installer aliases and keeps unrelated aliases" {
    local unrelated_alias="${BATS_TEST_TMPDIR}/unrelated-codex"
    local installer_output

    printf '#!/bin/sh\nexit 0\n' > "${unrelated_alias}"
    chmod +x "${unrelated_alias}"

    run env INSTALLER_EXIT_CODE=17 INSTALLER_USER_ALIAS="${unrelated_alias}" bash "${SCRIPT_PATH}"

    [ "${status}" -eq 1 ]
    [ -f "${INSTALLER_RELEASE_PATH}" ]
    [ "$(cat "${INSTALLER_RELEASE_PATH}")" = "${MISE_VERSION}" ]
    [ ! -e "${HOME}/.codex/daemon-bin/codex" ]
    [ -L "${HOME}/.local/bin/codex" ]
    [ "$(readlink "${HOME}/.local/bin/codex")" = "${unrelated_alias}" ]
    installer_output="$(cat "${CURL_OUTPUT_PATH}")"
    [ ! -e "${installer_output}" ]
    [ "$(wc -l < "${MISE_CALLS_PATH}")" -eq 1 ]
    [ -s "${CURL_CALLS_PATH}" ]
}
