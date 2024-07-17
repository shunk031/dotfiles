#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_gh() {
    type -p curl >/dev/null || sudo apt-install curl -y

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
        sudo apt-get update &&
        sudo apt-get install gh -y
}

function uninstall_gh() {
    sudo apt-get remove -y gh
}

function main() {
    install_gh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
