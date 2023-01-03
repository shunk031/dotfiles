#!/usr/bin/env bats

function setup() {
    . "$(chezmoi source-path)/install/ubuntu/common/golang.sh"
}

@test "install golang (ubuntu)" {
    main
    [ -x "$(command -v /usr/local/go/bin/go)" ]
}
