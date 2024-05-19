#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles" {
    files_exists=(
        "${HOME}/.config/git/ignore"
        "${HOME}/.config/git/config"
        "${HOME}/.config/jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings.json"
        "${HOME}/.config/tango.yml"
        "${HOME}/.local/bin/common/dev"
        "${HOME}/.local/bin/common/gpg.sh"
        "${HOME}/.local/bin/common/setup-gh"
        "${HOME}/.gnupg/gpg-agent.conf"
        "${HOME}/.ssh/config"
        "${HOME}/.vimrc"
        "${HOME}/.tmux.conf"
    )
    for file in "${files_exists[@]}"; do
        echo "Checking ${file}"
        [ -f "${file}" ]
    done

    directories_exists=(
        "${HOME}/.config/fzf"
        "${HOME}/.spacemacs.d"
        "${HOME}/.pyenv"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done

    symbolic_links_exists=(
        "${HOME}/.zshrc"
        "${HOME}/.zprofile"
    )
    for link in "${symbolic_links_exists[@]}"; do
        echo "Checking ${link}"
        [ -L "${link}" ]
    done
}
