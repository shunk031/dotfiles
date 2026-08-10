#!/usr/bin/env bash

# @file install/ubuntu/server/ssh_server.sh
# @brief Install and configure an Ubuntu SSH server.
# @description
#   Installs `openssh-server`, relaxes the container-oriented SSH settings used
#   by this repository, and starts the SSH service when running inside Docker.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

declare -r SSH_PORT="${DOTFILES_SERVER_SSH_PORT:-22}"
declare -r SSHD_CONFIG_PATH="${DOTFILES_SSHD_CONFIG_PATH:-/etc/ssh/sshd_config}"
declare -r SSH_SERVICE_COMMAND="${DOTFILES_SSH_SERVICE_COMMAND:-/usr/sbin/service}"
declare -r SSH_SERVICE_NAME="${DOTFILES_SSH_SERVICE_NAME:-ssh}"

#
# @description Install the Ubuntu OpenSSH server package and its prerequisites.
#
function install_openssh_server() {
    # install openssh-server and vim
    sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install --no-install-recommends -y \
        vim \
        openssh-server
}

#
# @description Merge proxy variables into `AcceptEnv` in `sshd_config`.
#
function configure_accept_env() {
    local merged value
    local -a add values

    add=(
        HTTP_PROXY
        HTTPS_PROXY
        NO_PROXY
        http_proxy
        https_proxy
        no_proxy
    )
    values=()

    while IFS= read -r value; do
        if [ -n "${value}" ]; then
            values+=("${value}")
        fi
    done < <(awk '/^[[:space:]]*AcceptEnv[[:space:]]/ { for (i = 2; i <= NF; i++) print $i }' "${SSHD_CONFIG_PATH}")

    values+=("${add[@]}")
    merged=$(printf '%s\n' "${values[@]}" | awk 'NF && !seen[$0]++ { printf "%s%s", sep, $0; sep = " " }')

    sudo sed -i '/^[[:space:]]*AcceptEnv[[:space:]]/d' "${SSHD_CONFIG_PATH}"
    printf 'AcceptEnv %s\n' "${merged}" | sudo tee -a "${SSHD_CONFIG_PATH}" > /dev/null
}

#
# @description Configure `sshd` for the repository's container-oriented setup.
#
function setup_sshd() {
    sudo mkdir -p /var/run/sshd
    mkdir -p ${HOME}/.ssh

    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' "${SSHD_CONFIG_PATH}" &&
        sudo sed -i "s/^#\?Port .*/Port ${SSH_PORT}/" "${SSHD_CONFIG_PATH}" &&
        sudo sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' "${SSHD_CONFIG_PATH}" &&
        sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "${SSHD_CONFIG_PATH}" &&
        sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

    configure_accept_env

    sudo /usr/sbin/sshd -t

    touch ${HOME}/.ssh/authorized_keys
}

#
# @description Reload the SSH service when it is running, otherwise start it.
#
function run_sshd() {
    if sudo "${SSH_SERVICE_COMMAND}" "${SSH_SERVICE_NAME}" status > /dev/null 2>&1; then
        sudo "${SSH_SERVICE_COMMAND}" "${SSH_SERVICE_NAME}" reload || sudo "${SSH_SERVICE_COMMAND}" "${SSH_SERVICE_NAME}" restart
        return
    fi

    sudo "${SSH_SERVICE_COMMAND}" "${SSH_SERVICE_NAME}" start
}

#
# @description Install, configure, and start the Ubuntu SSH server.
#
function main() {
    install_openssh_server
    setup_sshd
    run_sshd
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -f "/.dockerenv" ]; then
        main
    fi
fi
