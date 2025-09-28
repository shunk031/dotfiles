#!/usr/bin/env bash

# for finding directory of neologd dictionary
# alias which-neologd='echo `mecab-config --dicdir`"/mecab-ipadic-neologd"'
# alias ns='watch -n 1 "nvidia-smi"'
# alias resetport='lsof -t -i tcp:8000 | xargs kill -9'
alias ls="exa --long --group --header --binary --time-style=long-iso --icons"
alias gcloud='docker run --rm -it -v "${HOME%/}"/.config/gcloud:/root/.config/gcloud gcr.io/google.com/cloudsdktool/cloud-sdk gcloud'

# alias for bash-language-server in docker container
alias bash-language-server="docker run --platform linux/amd64 --rm -i ghcr.io/shunk031/bash-language-server:latest"
