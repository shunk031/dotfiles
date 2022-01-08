#!/usr/bin/env bash

function test_file_check() {
    
    local dotfiles=(
        "$HOME/.aspell_conf"
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux-powerlinerc"
        "$HOME/.tmux.conf"
        "$HOME/.vimrc"
        "$HOME/.zlogin"
        "$HOME/.zlogout"
        "$HOME/.zpreztorc"
        "$HOME/.zprofile"
        "$HOME/.zshenv"
        "$HOME/.zshrc"
    )

    for dotfile in ${dotfiles[@]}
    do
        if [ ! -f "$dotfile" ]; then
            echo "$dotfile does not exists."
            exit 1
        fi

    done
}

# test_file_check
