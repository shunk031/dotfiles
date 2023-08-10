#!/usr/bin/env bash

# Homebrew will not auto-update before running `brew install`
export HOMEBREW_NO_AUTO_UPDATE=1

# alias for tailscale
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# for lima docker
# export DOCKER_HOST="unix://$HOME/.colima/docker.sock"
export DOCKER_HOST=unix:///var/run/docker.sock
