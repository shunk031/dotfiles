#!/usr/bin/env bats

function setup() {
    . "./install/ubuntu/common/golang.sh"
}

@test "install golang (ubuntu)" {
    main
    export PATH="${PATH}:/usr/local/go/bin"
    [ -x "$(command -v go)" ]
}
