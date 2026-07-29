#!/usr/bin/env bash

# @file install/common/mise.sh
# @brief Install and bootstrap `mise`.
# @description
#   Reads the required mise version from the mise config, installs or updates the
#   standalone `mise` binary when needed, and runs `mise install`.

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
MISE_CONFIG_PATH="${MISE_CONFIG_PATH:-${HOME}/.config/mise/config.toml}"

#
# @description Read the top-level mise min_version from a TOML config.
# @arg $1 path Path to the mise config file.
# @stdout The configured mise version without a leading `v`.
# @stderr An error when the config is missing, unreadable, or malformed.
# @exitcode 0 When a valid top-level min_version is found.
# @exitcode 1 When min_version cannot be read.
#
function get_mise_min_version_from_config() {
    local path="$1"
    local line

    if [ ! -r "${path}" ]; then
        printf 'mise config is not readable: %s\n' "${path}" >&2
        return 1
    fi

    while IFS= read -r line || [ -n "${line}" ]; do
        if [[ "${line}" =~ ^[[:space:]]*\[ ]]; then
            break
        fi

        if [[ "${line}" =~ ^[[:space:]]*min_version[[:space:]]*= ]]; then
            if [[ "${line}" =~ ^[[:space:]]*min_version[[:space:]]*=[[:space:]]*\"([0-9]+[.][0-9]+[.][0-9]+)\"[[:space:]]*(#.*)?$ ]]; then
                printf '%s\n' "${BASH_REMATCH[1]}"
                return 0
            fi

            printf 'invalid top-level mise min_version in %s\n' "${path}" >&2
            return 1
        fi
    done < "${path}"

    printf 'top-level mise min_version was not found in %s\n' "${path}" >&2
    return 1
}

#
# @description Build the GitHub release tag for the configured mise version.
# @arg $1 path Path to the mise config file.
# @stdout The mise GitHub release tag with a leading `v`.
# @stderr An error when the configured version cannot be read.
# @exitcode 0 When a release tag can be built.
# @exitcode 1 When the configured version cannot be read.
#
function get_mise_release_tag_from_config() {
    local version

    version="$(get_mise_min_version_from_config "$1")" || return 1
    printf 'v%s\n' "${version#v}"
}

#
# @description Print the installed mise version.
# @stdout The installed mise version without a leading `v`.
# @exitcode 0 When the installed version can be parsed.
# @exitcode 1 When mise is missing or the version output is not parseable.
#
function get_installed_mise_version() {
    local output

    if [ ! -x "${MISE_INSTALL_PATH}" ]; then
        return 1
    fi

    output="$("${MISE_INSTALL_PATH}" --version)" || return 1
    if [[ "${output}" =~ ([0-9]+[.][0-9]+[.][0-9]+) ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

#
# @description Test whether a mise version is at least a required version.
# @arg $1 current Installed mise version without a leading `v`.
# @arg $2 required Required mise version without a leading `v`.
# @exitcode 0 When current is greater than or equal to required.
# @exitcode 1 When current is lower than required or either version is malformed.
#
function is_mise_version_at_least() {
    local current="$1"
    local required="$2"
    local current_parts required_parts index

    if [[ ! "${current}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
        return 1
    fi
    if [[ ! "${required}" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
        return 1
    fi

    IFS=. read -r -a current_parts <<< "${current}"
    IFS=. read -r -a required_parts <<< "${required}"

    for index in 0 1 2; do
        if ((10#${current_parts[index]} > 10#${required_parts[index]})); then
            return 0
        fi
        if ((10#${current_parts[index]} < 10#${required_parts[index]})); then
            return 1
        fi
    done

    return 0
}

#
# @description Install the configured standalone `mise` binary.
#
function install_mise() {
    # https://mise.run
    local version url installer

    version="$(get_mise_release_tag_from_config "${MISE_CONFIG_PATH}")" || return 1
    url="https://github.com/jdx/mise/releases/download/${version}/install.sh"
    installer="$(mktemp)" || return 1

    if ! curl -fsSL "${url}" -o "${installer}"; then
        rm -f "${installer}"
        return 1
    fi

    if ! MISE_VERSION="${version}" sh "${installer}"; then
        rm -f "${installer}"
        return 1
    fi

    rm -f "${installer}"
}

#
# @description Install mise when it is missing or older than the configured min_version.
#
function ensure_mise_min_version() {
    local required current

    required="$(get_mise_min_version_from_config "${MISE_CONFIG_PATH}")" || return 1
    current="$(get_installed_mise_version)" || {
        install_mise
        return $?
    }

    if ! is_mise_version_at_least "${current}" "${required}"; then
        install_mise
    fi
}

#
# @description Activate the installed mise binary for the current Bash process.
#
function activate_mise() {
    eval "$("${MISE_INSTALL_PATH}" activate bash)"
}

#
# @description Run `mise install` with release-age policy from the mise config.
#
function run_mise_install() {
    # These installer envvars are interpreted by mise as tool env overrides.
    unset MISE_CURRENT_VERSION
    unset MISE_VERSION
    "${MISE_INSTALL_PATH}" install
}

#
# @description Remove the standalone `mise` binary from the local bin dir.
#
function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

#
# @description Install or update `mise`, activate it, and install configured tools.
#
function main() {
    ensure_mise_min_version || return
    activate_mise || return
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
