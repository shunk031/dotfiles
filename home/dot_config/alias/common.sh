#!/usr/bin/env bash

# Use eza for ls command
alias ls="eza --long --group --header --binary --time-style=long-iso --icons"

# Alias for private chezmoi configuration
# ref. https://www.chezmoi.io/user-guide/frequently-asked-questions/design/#can-chezmoi-support-multiple-sources-or-multiple-source-states
alias chezmoi-private="chezmoi --source ~/.local/share/chezmoi-private --config ~/.config/chezmoi-private/chezmoi.yaml"
