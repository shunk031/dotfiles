#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/chezmoi.sh"
}

@test "install chezmoi (ubuntu)" {
    run main
    [ -x "$(command -v chezmoi)" ]
}
