#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/rocky/server/ssh_server.sh"

function setup() {
    export DOTFILES_SSHD_CONFIG_PATH="${BATS_TEST_TMPDIR}/sshd_config"
    export DOTFILES_SSHD_COMMAND=true
    export DOTFILES_SYSTEMCTL_COMMAND=true
    printf '%s\n' \
        'Port 22' \
        'AcceptEnv LANG LC_*' \
        'Match User nobody' \
        '    X11Forwarding no' > "${DOTFILES_SSHD_CONFIG_PATH}"

    function sudo() {
        "$@"
    }
    export -f sudo
}

@test "[rocky-server] configure_proxy_accept_env preserves global names and adds proxies before Match" {
    run bash -c '
        source "$1"
        configure_proxy_accept_env
        awk "/^AcceptEnv|^Match/ { print }" "${DOTFILES_SSHD_CONFIG_PATH}"
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "AcceptEnv LANG LC_* HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy" ]
    [ "${lines[1]}" = "Match User nobody" ]
}

@test "[rocky-server] configure_proxy_accept_env is idempotent" {
    run bash -c '
        source "$1"
        configure_proxy_accept_env
        first_checksum=$(cksum "${DOTFILES_SSHD_CONFIG_PATH}")
        configure_proxy_accept_env
        second_checksum=$(cksum "${DOTFILES_SSHD_CONFIG_PATH}")
        [ "${first_checksum}" = "${second_checksum}" ]
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
}

@test "[rocky-server] configure_proxy_accept_env leaves the original file when validation fails" {
    export DOTFILES_SSHD_COMMAND=false

    run bash -c '
        source "$1"
        configure_proxy_accept_env || true
        cat "${DOTFILES_SSHD_CONFIG_PATH}"
    ' _ "${SCRIPT_PATH}"

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "Port 22" ]
    [ "${lines[1]}" = "AcceptEnv LANG LC_*" ]
    [ "${lines[2]}" = "Match User nobody" ]
}
