#!/usr/bin/env zsh

typeset -gU path
path=(
    $path
    ${HOME}/.cargo/bin(N-/)
)
