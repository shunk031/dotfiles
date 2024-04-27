#!/usr/bin/env bash

#
# Use nvidia-smi alternative command
#
alias ns="watch -n 4 -cd nvinfo"

#
# Use eza or exa for ls command
#
if command -v "eza" >/dev/null 2>&1; then
    my_ls="eza"
else
    my_ls="exa"
fi
alias ls="${my_ls} --long --group --header --binary --time-style=long-iso --icons"
