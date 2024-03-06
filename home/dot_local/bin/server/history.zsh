#!/usr/bin/env zsh

setopt share_history
setopt append_history
setopt inc_append_history
setopt hist_no_store
setopt hist_ignore_all_dups
setopt hist_ignore_dups

export HISTFILE=${HISTFILE:-$HOME}/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
