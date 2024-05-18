#!/usr/bin/env bats

@test "[macos] dotfiles" {
    files_exists=(
        "~/.tmux.conf.d/system/client.conf"
        "~/.tmux.conf.d/os/macos.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}"]
    done

    files_not_exists=(
        "~/.tmux.conf.d/system/server.conf"
        "~/.tmux.conf.d/os/ubuntu_client.conf"
    )
}
