#!/usr/bin/env bats

function setup() {
    . "./install/macos/common/golang.sh"
}

@test "install golang (macos)" {
    main
    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
