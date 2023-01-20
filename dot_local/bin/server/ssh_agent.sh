#!/usr/bin/env bash

# set -Eeuox pipefail

eval "$(ssh-agent)" >/dev/null 2>&1
ssh-add "${HOME}/.ssh/id_rsa_github" >/dev/null 2>&1
