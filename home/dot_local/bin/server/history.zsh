#!/usr/bin/env zsh

setopt inc_append_history

export HISTFILE=${HISTFILE:-$HOME}/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
