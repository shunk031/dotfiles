#!/usr/bin/env bash

# @file install/rocky/server/ssh_server.sh
# @brief Allow SSH clients to provide proxy environment variables.
# @description
#   Merges a narrow proxy-variable allowlist into the global Rocky Linux sshd
#   configuration, validates a candidate file, and reloads sshd. A failed
#   reload restores the previous configuration.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly SSHD_CONFIG_PATH="${DOTFILES_SSHD_CONFIG_PATH:-/etc/ssh/sshd_config}"
readonly SSHD_COMMAND="${DOTFILES_SSHD_COMMAND:-/usr/sbin/sshd}"
readonly SYSTEMCTL_COMMAND="${DOTFILES_SYSTEMCTL_COMMAND:-systemctl}"

#
# @description Render sshd_config with proxy names merged into global AcceptEnv.
# @stdout The complete candidate sshd configuration.
#
function render_sshd_config() {
    sudo awk '
        function add_value(value) {
            if (!seen[value]++) {
                values[++value_count] = value
            }
        }

        function emit_accept_env() {
            if (accept_env_emitted) {
                return
            }

            add_value("HTTP_PROXY")
            add_value("HTTPS_PROXY")
            add_value("NO_PROXY")
            add_value("http_proxy")
            add_value("https_proxy")
            add_value("no_proxy")

            printf "AcceptEnv"
            for (i = 1; i <= value_count; i++) {
                printf " %s", values[i]
            }
            printf "\n"
            accept_env_emitted = 1
        }

        tolower($1) == "match" && !in_match {
            emit_accept_env()
            in_match = 1
        }

        !in_match && tolower($1) == "acceptenv" {
            for (i = 2; i <= NF; i++) {
                add_value($i)
            }
            next
        }

        { print }

        END {
            if (!accept_env_emitted) {
                emit_accept_env()
            }
        }
    ' "${SSHD_CONFIG_PATH}"
}

#
# @description Install, validate, and activate the proxy environment allowlist.
# @stderr Validation or reload failures from sshd and systemctl.
# @exitcode 0 When the active configuration contains the allowlist.
# @exitcode 1 When validation, installation, or reload fails.
#
function configure_proxy_accept_env() {
    local backup_path candidate_path

    candidate_path="$(mktemp)"
    backup_path="${SSHD_CONFIG_PATH}.backup.$$"
    render_sshd_config > "${candidate_path}"

    if sudo cmp -s "${candidate_path}" "${SSHD_CONFIG_PATH}"; then
        rm -f "${candidate_path}"
        return 0
    fi

    if ! sudo "${SSHD_COMMAND}" -t -f "${candidate_path}"; then
        rm -f "${candidate_path}"
        return 1
    fi

    sudo cp -p "${SSHD_CONFIG_PATH}" "${backup_path}"
    if ! sudo cp "${candidate_path}" "${SSHD_CONFIG_PATH}"; then
        sudo mv "${backup_path}" "${SSHD_CONFIG_PATH}"
        rm -f "${candidate_path}"
        return 1
    fi
    rm -f "${candidate_path}"

    if ! sudo "${SYSTEMCTL_COMMAND}" reload sshd; then
        sudo mv "${backup_path}" "${SSHD_CONFIG_PATH}"
        sudo "${SSHD_COMMAND}" -t && sudo "${SYSTEMCTL_COMMAND}" reload sshd
        return 1
    fi

    sudo rm -f "${backup_path}"
}

#
# @description Configure sshd to accept proxy variables from SSH clients.
#
function main() {
    configure_proxy_accept_env
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
