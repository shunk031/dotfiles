#!/usr/bin/env bats

@test "[macos] dotfiles" {
    files_exists=(
        "~/.config/powerlevel10k/p10k.zsh"
        "~/.local/bin/client"
        "~/.bash/client/bashrc"
        "~/.tmux.conf.d/system/client.conf"
        "~/.tmux.conf.d/os/macos.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    files_not_exists=(
        "~/.local/bin/server"
        "~/.tmux.conf.d/system/server.conf"
        "~/.tmux.conf.d/os/ubuntu_client.conf"
    )
    for file in "${files_not_exists[@]}"; do
        [ ! -f "${file}" ]
    done
}
