#!/usr/bin/env zsh

# set -Eeuox pipefail

export GOPATH="${HOME}/ghq"

typeset -gU path
path=(
    "${GOPATH}/bin"
    /usr/local/go/bin
    "$path"
)

GOROOT=$(go env GOROOT)
export GOROOT
