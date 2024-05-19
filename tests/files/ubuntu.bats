#!/usr/bin/env bats

# bats test_tags=ubuntu:client
@test "[ubuntu-client] dotfiles" {
    files_exists=(
        "~/.zsh/client/zshrc"
        "~/.zsh/client/zprofile"
        "~/.tmux.conf.d/system/client.conf"
        "~/.tmux.conf.d/os/ubuntu_client.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    files_not_exists=(
        "~/.zsh/server/zshrc"
        "~/.zsh/server/zprofile"
        "~/.tmux.conf.d/system/server.conf"
        "~/.tmux.conf.d/os/macosr.conf"
    )
    for file in "${files_not_exists[@]}"; do
        [ ! -f "${file}" ]
    done
}

# bats test_tags=ubuntu:server
@test "[ubuntu-server] dotfiles" {
    files_exists=(
        "~/.zsh/server/zshrc"
        "~/.zsh/server/zprofile"
        "~/.tmux.conf.d/system/server.conf"
        "~/.tmux.conf.d/os/ubuntu_server.conf"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    files_not_exists=(
        "~/.zsh/client/zshrc"
        "~/.zsh/client/zprofile"
        "~/.tmux.conf.d/system/client.conf"
        "~/.tmux.conf.d/os/macos.conf"
    )
    for file in "${files_not_exists[@]}"; do
        [ ! -f "${file}" ]
    done
}
