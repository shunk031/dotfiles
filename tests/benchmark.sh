#!/bin/bash

set -eu

rm -f benchmark-results/*

os=$(uname -s | tr '[A-Z]' '[a-z]')

case $os in
    darwin)
        TIME_COMMAND=gtime
    ;;
    linux)
        TIME_COMMAND=time
    ;;
esac

# 初回はインストールがあるので別で実行しておく
$TIME_COMMAND --format="%e" zsh -i -c exit 2> benchmark-results/zsh-install-time.txt

{ for i in $(seq 1 10); do $TIME_COMMAND --format="%e" zsh -i -c exit; done } 2> benchmark-results/zsh-load-time.txt

ZSH_LOAD_TIME=$(cat benchmark-results/zsh-load-time.txt | awk '{ total += $1 } END { print total/NR }')
ZSH_INSTALL_TIME=$(cat benchmark-results/zsh-install-time.txt)

cat<<EOJ
[
    {
        "name": "zsh load time",
        "unit": "Second",
        "value": ${ZSH_LOAD_TIME}
    },
    {
        "name": "zsh install time",
        "unit": "Second",
        "value": ${ZSH_INSTALL_TIME}
    }
]
EOJ
