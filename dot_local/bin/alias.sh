#!/usr/bin/env bash

# for finding directory of neologd dictionary
# alias which-neologd='echo `mecab-config --dicdir`"/mecab-ipadic-neologd"'
# alias ns='watch -n 1 "nvidia-smi"'
# alias resetport='lsof -t -i tcp:8000 | xargs kill -9'
alias ls="exa --long --group --header --binary --time-style=long-iso --icons"
alias gcloud="docker run --rm -it -v ${HOME}/.config/gcloud:/root/.config/gcloud gcr.io/google.com/cloudsdktool/cloud-sdk gcloud"

# # delete all git branches which have been "squash and merge" via GitHub
# # ref. https://stackoverflow.com/questions/43489303/how-can-i-delete-all-git-branches-which-have-been-squash-and-merge-via-github
alias gprunesquashmerged='git checkout -q master && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base master $branch) && [[ $(git cherry master $(git commit-tree $(git rev-parse "$branch^{tree}") -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done'

# # alias for bash-language-server in docker container
alias bash-language-server="docker run --rm -i bash-language-server:latest"
