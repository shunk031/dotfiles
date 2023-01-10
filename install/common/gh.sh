#!/usr/bin/env bash

set -Eeuox pipefail

function login_to_github() {
    gh auth login -h github.com -p https
}

function add_ssh_key_to_github() {
    gh auth refresh -h github.com -s admin:public_key
    gh ssh-key add "${HOME%/}/.ssh/id_ed25519.pub"
}

function main() {
    if ! "${CI:-false}"; then
        login_to_github
        add_ssh_key_to_github
    fi
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
