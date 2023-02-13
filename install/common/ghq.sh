#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly GHQ_DIR="${HOME%/}/ghq"

function make_ghq_dir() {
    mkdir -p "${GHQ_DIR}"
}

function remove_ghq_dir() {
    rm -rf "${GHQ_DIR}"
}

function main() {
    make_ghq_dir
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
