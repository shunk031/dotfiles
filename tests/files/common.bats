#!/usr/bin/env bats

@test "[common] dotfiles" {
    files_exists=(
        "~/.profile"
        "~/.zshrc"
        "~/.bashrc"
        "~/.tmux.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}"]
    done

    files_not_exists=(
        "~/.tmux.conf/os/server.conf"
    )
}
