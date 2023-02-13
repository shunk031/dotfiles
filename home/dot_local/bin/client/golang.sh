#!/usr/bin/env zsh

export GOPATH="${HOME}/ghq"

typeset -gU path
path=(
    $path
    ${GOPATH}/bin(N-/)
    /usr/local/go/bin(N-/)
)

export GOROOT=$(go env GOROOT)
