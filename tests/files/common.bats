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
        
        "~/.profile"
        "~/.zshrc"
        "~/.bashrc"
        "~/.tmux.conf"
        "~/.vimrc"
        "~/.bash"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    symbolic_links_exists=(
        "~/.jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings"
    )
    for link in "${symbolic_links_exists[@]}"; do
        [ -L "${link}" ]
    done
}
