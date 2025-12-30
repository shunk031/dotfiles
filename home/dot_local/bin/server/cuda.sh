#!/usr/bin/env zsh

export CUDA_HOME="/usr/local/cuda"

typeset -gU path
path+=(
    ${CUDA_HOME}/bin
)

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
