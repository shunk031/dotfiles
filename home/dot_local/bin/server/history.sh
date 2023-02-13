#!/usr/bin/env bash

function tac {
    exec sed '1!G;h;$!d' ${@+"$@"}
}

function share_history {
    history -a
    tac ~/.bash_history | awk '!a[$0]++' | tac >~/.bash_history.tmp

    [ -f ~/.bash_history.tmp ] &&
        mv ~/.bash_history{.tmp,} &&
        history -c &&
        history -r
}
export PROMPT_COMMAND="$PROMPT_COMMAND share_history;"
