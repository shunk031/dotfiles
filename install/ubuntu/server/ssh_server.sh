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
# @description Merge proxy-related variables into `AcceptEnv` in `sshd_config`.
#
function configure_accept_env() {
    local current add merged

    # Get existing AcceptEnv values (empty if not set)
    current=$(grep '^AcceptEnv' /etc/ssh/sshd_config | sed 's/^AcceptEnv //')

    # Variables to append
    add="HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy"

    # Merge and remove duplicates
    merged=$(echo "$current $add" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # Remove existing entries and keep a single AcceptEnv line
    sudo sed -i '/^AcceptEnv/d' /etc/ssh/sshd_config
    echo "AcceptEnv $merged" | sudo tee -a /etc/ssh/sshd_config
}

#
# @description Configure `sshd` for the repository's container-oriented setup.
#
function setup_sshd() {
    sudo mkdir -p /var/run/sshd
    mkdir -p ${HOME}/.ssh

    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sudo sed -i "s/^#\?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config &&
        sudo sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config &&
        sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

    configure_accept_env

    # check the /etc/ssh/sshd_config
    sudo /usr/sbin/sshd -t

    # create .ssh/authorized_keys if not exists
    touch ${HOME}/.ssh/authorized_keys
}

#
# @description Start the SSH service after configuration has been validated.
#
function run_sshd() {
    # run sshd
    sudo /usr/sbin/service ssh start
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
