#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/server/ssh_server.sh"

function run_ssh_server_function() {
    run env \
        DOTFILES_DEBUG= \
        DOTFILES_SSHD_CONFIG_PATH="${SSHD_CONFIG_PATH}" \
        DOTFILES_SSH_SERVICE_COMMAND=service_stub \
        DOTFILES_SSH_SERVICE_NAME=ssh \
        SCRIPT_PATH="${SCRIPT_PATH}" \
        SERVICE_CALLS_PATH="${SERVICE_CALLS_PATH}" \
        SERVICE_STATUS="${SERVICE_STATUS:-stopped}" \
        SERVICE_RELOAD_STATUS="${SERVICE_RELOAD_STATUS:-0}" \
        bash -c '
            source "${SCRIPT_PATH}"

            sudo() {
                "$@"
            }

            tee() {
                if [ "$1" = "-a" ]; then
                    shift
                    command tee -a "$@"
                    return
                fi

                command tee "$@"
            }

            service_stub() {
                printf "%s\n" "$*" >> "${SERVICE_CALLS_PATH}"

                case "$2" in
                    status)
                        [ "${SERVICE_STATUS}" = "running" ]
                        ;;
                    reload)
                        return "${SERVICE_RELOAD_STATUS}"
                        ;;
                    *)
                        return 0
                        ;;
                esac
            }

            "$1"
        ' bash "$1"
}

function setup() {
    SSHD_CONFIG_PATH="${BATS_TEST_TMPDIR}/sshd_config"
    SERVICE_CALLS_PATH="${BATS_TEST_TMPDIR}/service_calls.txt"
    export SSHD_CONFIG_PATH SERVICE_CALLS_PATH
    : > "${SERVICE_CALLS_PATH}"
}

@test "[ubuntu-common] configure_accept_env adds CLIProxyAPI variables" {
    cat > "${SSHD_CONFIG_PATH}" << 'EOF'
Port 22
AcceptEnv LANG LC_*
EOF

    run_ssh_server_function configure_accept_env
    [ "${status}" -eq 0 ]

    run grep '^AcceptEnv ' "${SSHD_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"CLI_PROXY_API_CALLBACK_PORT"* ]]
    [[ "${output}" == *"CLI_PROXY_API_PROXY_URL"* ]]
}

@test "[ubuntu-common] configure_accept_env preserves existing env vars and deduplicates" {
    cat > "${SSHD_CONFIG_PATH}" << 'EOF'
AcceptEnv LANG HTTP_PROXY
AcceptEnv CLI_PROXY_API_PROXY_URL NO_PROXY
EOF

    run_ssh_server_function configure_accept_env
    [ "${status}" -eq 0 ]

    run awk '
        /^AcceptEnv / {
            lines++
            for (i = 2; i <= NF; i++) counts[$i]++
        }
        END {
            if (lines != 1) exit 1
            if (counts["LANG"] != 1) exit 2
            if (counts["HTTP_PROXY"] != 1) exit 3
            if (counts["NO_PROXY"] != 1) exit 4
            if (counts["CLI_PROXY_API_PROXY_URL"] != 1) exit 5
            if (counts["CLI_PROXY_API_CALLBACK_PORT"] != 1) exit 6
        }
    ' "${SSHD_CONFIG_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[ubuntu-common] run_sshd reloads running ssh service" {
    export SERVICE_STATUS="running"

    run_ssh_server_function run_sshd
    [ "${status}" -eq 0 ]

    run cat "${SERVICE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "ssh status" ]
    [ "${lines[1]}" = "ssh reload" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "[ubuntu-common] run_sshd restarts running ssh service when reload fails" {
    export SERVICE_STATUS="running"
    export SERVICE_RELOAD_STATUS="1"

    run_ssh_server_function run_sshd
    [ "${status}" -eq 0 ]

    run cat "${SERVICE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "ssh status" ]
    [ "${lines[1]}" = "ssh reload" ]
    [ "${lines[2]}" = "ssh restart" ]
    [ "${#lines[@]}" -eq 3 ]
}

@test "[ubuntu-common] run_sshd starts stopped ssh service" {
    export SERVICE_STATUS="stopped"

    run_ssh_server_function run_sshd
    [ "${status}" -eq 0 ]

    run cat "${SERVICE_CALLS_PATH}"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "ssh status" ]
    [ "${lines[1]}" = "ssh start" ]
    [ "${#lines[@]}" -eq 2 ]
}
