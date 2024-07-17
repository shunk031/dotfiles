#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi
 
function install_openssh_server() {
    # install openssh-server and vim
    sudo apt-get update && sudo apt-get install --no-install-recommends -y \
        vim \
        openssh-server
}
 
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
 
function run_sshd() {
    # run sshd
    sudo /usr/sbin/service ssh start
}
 
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
