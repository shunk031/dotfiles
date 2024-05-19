#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles" {
    files_exists=(
        "~/.config/fzf"
        "~/.config/git/ignore"
        "~/.config/git/config"
        "~/.config/jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings.json"
        "~/.config/tango.yml"
        "~/.local/bin/common/dev"
        "~/.local/bin/common/gpg.sh"
        "~/.local/bin/common/setup-gh"
        "~/.spacemacs.d"
        "~/.gnupg/gpg-agent.conf"
        "~/.ssh/config"
        "~/.profile"
        "~/.vimrc"
        "~/.tmux.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    symbolic_links_exists=(
        "~/.zshrc"
        "~/.zprofile"
    )
    for link in "${symbolic_links_exists[@]}"; do
        [ -L "${link}" ]
    done
}
