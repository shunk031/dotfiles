#!/usr/bin/env bash

# @file home/dot_local/bin/server/ssh_agent.sh
# @brief Start `ssh-agent` and load the default SSH key.
# @description
#   Starts a new `ssh-agent` process and adds the default ed25519 private key
#   for the current user.

eval "$(ssh-agent)" > /dev/null 2>&1
ssh-add "${HOME}/.ssh/id_ed25519" > /dev/null 2>&1
