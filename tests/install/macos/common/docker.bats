#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/macos/common/docker.sh"
}

@test "install docker" {
    main

    [ -x "$(command -v lima)" ]
    [ -x "$(command -v colima)" ]
    [ -x "$(command -v docker)" ]
    [ -x "$(command -v docker-compose)" ]
}
