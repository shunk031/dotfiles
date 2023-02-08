#!/usr/bin/env bash

eval "$(ssh-agent)" >/dev/null 2>&1
ssh-add "${HOME}/.ssh/id_ed25519" >/dev/null 2>&1
