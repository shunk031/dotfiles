#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/client/docker.sh"
}

@test "install docker" {
    main

    run dpkg -s 'docker-ce'
    [ "${status}" -eq 0 ]
    run dpkg -s 'docker-ce-cli'
    [ "${status}" -eq 0 ]
    run dpkg -s 'containerd.io'
    [ "${status}" -eq 0 ]
    run dpkg -s 'docker-compose-plugin'
    [ "${status}" -eq 0 ]
}
