#!/usr/bin/env bash

set -Eeuox pipefail

function make_ghq_dir() {
    local ghq_dir="${HOME%/}/ghq"
    mkdir -p "${ghq_dir}"
}

function main() {
    make_ghq_dir
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
