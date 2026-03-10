#!/usr/bin/env bash

# Use eza for ls command
alias ls="eza --long --group --header --binary --time-style=long-iso --icons"

# Alias for private chezmoi configuration
# ref. https://www.chezmoi.io/user-guide/frequently-asked-questions/design/#can-chezmoi-support-multiple-sources-or-multiple-source-states
alias chezmoi-private="chezmoi --source ~/.local/share/chezmoi-private --config ~/.config/chezmoi-private/chezmoi.yaml"

# Alias for claude-mem
alias claude-mem='$HOME/.bun/bin/bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Alias to checkout the default branch in git
alias gm='git checkout $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")'
