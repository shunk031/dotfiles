#!/usr/bin/env bash

# @file install/common/codex-remote-control.sh
# @brief Install the standalone Codex package required by remote control.
# @description
#   Keeps the user-facing Codex CLI managed by mise while provisioning the
#   matching standalone package that the remote-control daemon executes. Set
#   `CODEX_REMOTE_CONTROL_ENABLED=1` only on hosts that should receive it.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"
readonly CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
readonly CODEX_DAEMON_BIN="${CODEX_HOME_DIR}/packages/standalone/current/codex"
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
# @description Check whether the installed daemon matches the mise Codex.
# @arg $1 expected_version Version expected by the daemon.
# @exitcode 0 When the daemon exists and matches.
# @exitcode 1 When it is missing or has another version.
#
function daemon_matches_codex() {
    local expected_version="$1"
    local output daemon_version

    [ -x "${CODEX_DAEMON_BIN}" ] || return 1
    output="$("${CODEX_DAEMON_BIN}" --version 2> /dev/null)" || return 1
    daemon_version="$(extract_codex_version "${output}")" || return 1
    [ "${daemon_version}" = "${expected_version}" ]
}

#
# @description Remove only aliases that point into the managed standalone package.
# @arg $1 alias_path Path of a CLI alias created by the official installer.
#
function remove_standalone_alias() {
    local alias_path="$1"
    local target

    [ -L "${alias_path}" ] || return 0
    target="$(readlink "${alias_path}")"
    case "${target}" in
    "${CODEX_HOME_DIR}/packages/standalone/current/"*)
        rm -f "${alias_path}"
        ;;
    esac
}

#
# @description Remove the temporary visible aliases left by the installer.
#
function remove_standalone_aliases() {
    remove_standalone_alias "${CODEX_INSTALL_DIR}/codex"
    remove_standalone_alias "${HOME}/.local/bin/codex"
}

#
# @description Install the daemon package at the same version as mise Codex.
# @arg $1 version Codex release version to install.
# @exitcode 0 When the package is installed.
# @exitcode 1 When the official installer fails or the daemon is missing.
#
function install_codex_daemon() {
    local version="$1"
    local installer

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
        CODEX_RELEASE="${version}" \
        CODEX_NON_INTERACTIVE=true \
        sh "${installer}"; then
        rm -f "${installer}"
        remove_standalone_aliases
        return 1
    fi

    rm -f "${installer}"
    remove_standalone_aliases
    [ -x "${CODEX_DAEMON_BIN}" ]
}

#
# @description Ensure remote control has a matching standalone Codex daemon.
#
function install_codex_remote_control() {
    local version

    [ "${CODEX_REMOTE_CONTROL_ENABLED:-}" = "1" ] || return 0

    version="$(get_mise_codex_version)" || {
        printf '%s\n' 'unable to read the mise-managed Codex version' >&2
        return 1
    }

    if daemon_matches_codex "${version}"; then
        remove_standalone_aliases
        return 0
    fi

    install_codex_daemon "${version}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_codex_remote_control
fi
