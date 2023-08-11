#!/usr/bin/env zsh

# for golang
export GOPATH="${HOME}/ghq"

typeset -gU path
path=(
    $path
    /usr/local/go/bin(N-/)
    ${GOPATH}/bin(N-/)
)
