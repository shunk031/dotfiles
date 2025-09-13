#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function main() {
    chezmoi init \
        --apply \
        --ssh \
        --source ~/.local/share/chezmoi-private \
        --config ~/.config/chezmoi/chezmoi.yaml \
        shunk031/dotfiles-private
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
