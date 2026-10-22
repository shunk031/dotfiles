#!/usr/bin/env bash

# @file install/common/codex-remote-control.sh
# @brief Install and start the Codex daemon required by remote control.
# @description
#   Keeps the user-facing Codex CLI managed by mise while provisioning the
#   matching package that the remote-control daemon executes. Set
#   `CODEX_REMOTE_CONTROL_ENABLED=1` only on hosts that should receive it.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
readonly CODEX_APP_SERVER_DAEMON_PACKAGE_DIR="${CODEX_HOME_DIR}/packages/app-server-daemon"
readonly CODEX_STANDALONE_PACKAGE_DIR="${CODEX_HOME_DIR}/packages/standalone"
readonly CODEX_APP_SERVER_DAEMON_STATE_DIR="${CODEX_HOME_DIR}/app-server-daemon"
readonly CODEX_INSTALL_DIR="${CODEX_HOME_DIR}/daemon-bin"
readonly CODEX_INSTALLER_URL="https://chatgpt.com/codex/install.sh"
readonly CODEX_INSTALLER_PATH="${CODEX_INSTALL_DIR}:/usr/bin:/bin"

#
# @description Extract a semantic version from Codex's version output.
# @arg $1 output Version output such as `codex-cli 0.157.1`.
# @stdout The Codex version.
# @exitcode 0 When a version is found.
# @exitcode 1 When the output does not contain a version.
#
function extract_codex_version() {
    local output="$1"

    if [[ "${output}" =~ ([0-9]+[.][0-9]+[.][0-9]+([-.][[:alnum:]_.+-]+)?) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

#
# @description Read the Codex version installed by mise.
# @stdout The mise-managed Codex version.
# @exitcode 0 When the mise-managed Codex version can be read.
# @exitcode 1 When mise or Codex is unavailable or unparsable.
#
function get_mise_codex_version() {
    local output

    output="$("${MISE_BIN}" exec -- codex --version)" || return 1
    extract_codex_version "${output}"
}

#
# @description Resolve Codex's selected package, including legacy daemon state.
# @stdout The package directory selected for daemon commands.
#
function get_codex_daemon_package_dir() {
    local artifact
    local dedicated_current="${CODEX_APP_SERVER_DAEMON_PACKAGE_DIR}/current"

    if [ -e "${dedicated_current}" ] || [ -L "${dedicated_current}" ]; then
        printf '%s\n' "${CODEX_APP_SERVER_DAEMON_PACKAGE_DIR}"
        return
    fi

    for artifact in daemon.pid daemon.stderr.log daemon-updater.pid daemon-updater.stderr.log; do
        if [ -e "${CODEX_APP_SERVER_DAEMON_STATE_DIR}/${artifact}" ] ||
            [ -L "${CODEX_APP_SERVER_DAEMON_STATE_DIR}/${artifact}" ]; then
            printf '%s\n' "${CODEX_APP_SERVER_DAEMON_PACKAGE_DIR}"
            return
        fi
    done

    for artifact in app-server.pid app-server.stderr.log app-server-updater.pid app-server-updater.stderr.log; do
        if [ -e "${CODEX_APP_SERVER_DAEMON_STATE_DIR}/${artifact}" ] ||
            [ -L "${CODEX_APP_SERVER_DAEMON_STATE_DIR}/${artifact}" ]; then
            printf '%s\n' "${CODEX_STANDALONE_PACKAGE_DIR}"
            return
        fi
    done

    printf '%s\n' "${CODEX_APP_SERVER_DAEMON_PACKAGE_DIR}"
}

#
# @description Check whether the installed daemon matches the mise Codex.
# @arg $1 package_dir Codex package selected by the daemon commands.
# @arg $2 expected_version Version expected by the daemon.
# @exitcode 0 When the daemon exists and matches.
# @exitcode 1 When it is missing or has another version.
#
function daemon_matches_codex() {
    local package_dir="$1"
    local expected_version="$2"
    local output daemon_version
    local daemon_bin="${package_dir}/current/codex"

    [ -x "${daemon_bin}" ] || return 1
    output="$("${daemon_bin}" --version 2> /dev/null)" || return 1
    daemon_version="$(extract_codex_version "${output}")" || return 1
    [ "${daemon_version}" = "${expected_version}" ]
}

#
# @description Remove only aliases that point into the selected managed package.
# @arg $1 alias_path Path of a CLI alias created by the official installer.
# @arg $2 package_dir Codex package selected by the daemon commands.
#
function remove_codex_alias() {
    local alias_path="$1"
    local package_dir="$2"
    local target

    [ -L "${alias_path}" ] || return 0
    target="$(readlink "${alias_path}")"
    case "${target}" in
    "${package_dir}/current/"*)
        rm -f "${alias_path}"
        ;;
    esac
}

#
# @description Remove the temporary visible aliases left by the installer.
# @arg $1 package_dir Codex package selected by the daemon commands.
#
function remove_codex_aliases() {
    local package_dir="$1"

    remove_codex_alias "${CODEX_INSTALL_DIR}/codex" "${package_dir}"
    remove_codex_alias "${HOME}/.local/bin/codex" "${package_dir}"
}

#
# @description Install the selected daemon package at the same version as mise Codex.
# @arg $1 version Codex release version to install.
# @arg $2 package_dir Codex package selected by the daemon commands.
# @exitcode 0 When the package is installed.
# @exitcode 1 When the official installer fails or the daemon is missing.
#
function install_codex_daemon() {
    local version="$1"
    local package_dir="$2"
    local installer
    local daemon_only=0

    if [ "${package_dir}" = "${CODEX_APP_SERVER_DAEMON_PACKAGE_DIR}" ]; then
        daemon_only=1
    fi

    mkdir -p "${CODEX_INSTALL_DIR}"
    installer="$(mktemp)"

    if ! curl -fsSL "${CODEX_INSTALLER_URL}" -o "${installer}"; then
        rm -f "${installer}"
        return 1
    fi

    if ! env \
        PATH="${CODEX_INSTALLER_PATH}" \
        CODEX_HOME="${CODEX_HOME_DIR}" \
        CODEX_INSTALL_DIR="${CODEX_INSTALL_DIR}" \
        CODEX_INSTALL_DAEMON_ONLY="${daemon_only}" \
        CODEX_RELEASE="${version}" \
        CODEX_NON_INTERACTIVE=true \
        sh "${installer}"; then
        rm -f "${installer}"
        remove_codex_aliases "${package_dir}"
        return 1
    fi

    rm -f "${installer}"
    remove_codex_aliases "${package_dir}"
    [ -x "${package_dir}/current/codex" ]
}

#
# @description Enable remote control for future starts and the running daemon.
#
function enable_remote_control() {
    "${MISE_BIN}" exec -- codex app-server daemon enable-remote-control
}

#
# @description Start the local app-server daemon when it is not running.
#
function start_codex_daemon() {
    "${MISE_BIN}" exec -- codex app-server daemon start
}

#
# @description Ensure remote control has a matching Codex daemon package.
#
function install_codex_remote_control() {
    local version
    local package_dir

    [ "${CODEX_REMOTE_CONTROL_ENABLED:-}" = "1" ] || return 0

    version="$(get_mise_codex_version)" || {
        printf '%s\n' 'unable to read the mise-managed Codex version' >&2
        return 1
    }

    package_dir="$(get_codex_daemon_package_dir)"
    if daemon_matches_codex "${package_dir}" "${version}"; then
        remove_codex_aliases "${package_dir}"
    else
        install_codex_daemon "${version}" "${package_dir}"
    fi

    enable_remote_control
    start_codex_daemon
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_codex_remote_control
fi
