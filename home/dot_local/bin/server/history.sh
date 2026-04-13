#!/usr/bin/env bash

# @file home/dot_local/bin/server/history.sh
# @brief Share shell history across concurrent bash sessions.
# @description
#   Provides a `tac` fallback and appends a `PROMPT_COMMAND` hook that merges
#   duplicate-filtered bash history back into the main history file.

# @description Reverse lines from stdin or files using `sed`.
function tac {
    exec sed '1!G;h;$!d' ${@+"$@"}
}

# @description Merge the current bash session history back into `~/.bash_history`.
function share_history {
    history -a
    tac ~/.bash_history | awk '!a[$0]++' | tac > ~/.bash_history.tmp

    [ -f ~/.bash_history.tmp ] &&
        mv ~/.bash_history{.tmp,} &&
        history -c &&
        history -r
}
export PROMPT_COMMAND="$PROMPT_COMMAND share_history;"
