#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_latex() {
    brew install texlive latexindent
}

function uninstall_latex() {
    brew uninstall texlive latexindent
}

function main() {
    install_latex
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
