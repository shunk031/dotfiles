#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/client/docker.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_docker_engine
}

@test "[ubuntu-client] docker" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s 'docker-ce'
    [ "${status}" -eq 0 ]
    run dpkg -s 'docker-ce-cli'
    [ "${status}" -eq 0 ]
    run dpkg -s 'containerd.io'
    [ "${status}" -eq 0 ]
    run dpkg -s 'docker-compose-plugin'
    [ "${status}" -eq 0 ]
}
