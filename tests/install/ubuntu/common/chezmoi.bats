#!/usr/bin/env bats

set -Eeuo pipefail

function setup() {
    . "./install/ubuntu/common/chezmoi.sh"
}

@test "install chezmoi (ubuntu)" {
    main
    [ -x "$(command -v chezmoi)" ]
}
