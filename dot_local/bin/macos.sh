#!/usr/bin/env bash

# Add homebrew to the PATH
eval "$(brew shellenv)"

# Homebrew will not auto-update before running `brew install`
export HOMEBREW_NO_AUTO_UPDATE=1

# alias for tailscale
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# for lima docker
export DOCKER_HOST=$(limactl list docker_x86_64 --format 'unix://{{.Dir}}/sock/docker.sock')
