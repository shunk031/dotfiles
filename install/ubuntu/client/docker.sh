#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-compose-plugin
)

function uninstall_old_docker() {
    local packages=(
        "docker"
        "docker-engine"
        "docker.io"
        "containerd"
        "runc"
    )
    for package in "${packages[@]}"; do
        if dpkg -s "${package}" >/dev/null 2>&1; then
            sudo apt-get remove -y "${package}"
        fi
    done
}

function setup_repository() {

    # Update the apt package index and install packages to allow apt to use a repository over HTTPS:
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker’s official GPG key:
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Use the following command to set up the repository:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
}

function install_docker_engine() {
    # Update the apt package index:
    sudo apt-get update

    # Install Docker Engine, containerd, and Docker Compose.
    sudo apt-get install -y "${PACKAGES[@]}"

}

function uninstall_docker_engine() {
    sudo apt-get remove -y "${PACKAGES[@]}"
}

function main() {
    uninstall_old_docker
    setup_repository
    install_docker_engine
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
