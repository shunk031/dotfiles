#!/usr/bin/env bash

# @file install/ubuntu/server/ssh_server.sh
# @brief OpenSSH server installation and configuration script
# @description
#   This script installs and configures OpenSSH server for Ubuntu,
#   particularly optimized for Docker containers. It sets up SSH daemon
#   with appropriate security settings and starts the service.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Install OpenSSH server and vim
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_openssh_server
function install_openssh_server() {
    # install openssh-server and vim
    sudo apt-get update && sudo apt-get install --no-install-recommends -y \
        vim \
        openssh-server
}

# @description Configure SSH daemon settings
# @exitcode 0 On successful configuration
# @exitcode 1 If configuration fails
# @example
#   setup_sshd
function setup_sshd() {
    sudo mkdir -p /var/run/sshd
    mkdir -p ${HOME}/.ssh
 
    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&
        sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config &&
        sudo sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config &&
        sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        sudo sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
 
    # check the /etc/ssh/sshd_config
    sudo /usr/sbin/sshd -t
 
    # create .ssh/authorized_keys if not exists
    touch ${HOME}/.ssh/authorized_keys
}
 
# @description Start the SSH daemon service
# @exitcode 0 On successful start
# @exitcode 1 If start fails
# @example
#   run_sshd
function run_sshd() {
    # run sshd
    sudo /usr/sbin/service ssh start
}

# @description Main entry point for SSH server installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./ssh_server.sh
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
