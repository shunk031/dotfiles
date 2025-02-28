#!/usr/bin/env zsh

typeset -gU path
path=(
    $path
    ${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin(N-/)
)
