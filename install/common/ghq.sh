#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function make_ghq_dir() {
    local ghq_dir="${HOME%/}/ghq"
    mkdir -p "${ghq_dir}"
}

function main() {
    make_ghq_dir
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
