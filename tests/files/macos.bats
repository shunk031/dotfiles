#!/usr/bin/env bats

@test "[macos] dotfiles" {
    files_exists=(
        "~/.config/powerlevel10k/p10k.zsh"
        "~/.local/bin/client"
        "~/.zsh/client/zshrc"
        "~/.zsh/client/zprofile"
        "~/.bash/client/bashrc"
        "~/.tmux-powerlinerc"
        "~/.tmux.conf.d/system/client.conf"
        "~/.tmux.conf.d/os/macos.conf"
        "~/.zprezto"
    )
    for file in "${files_exists[@]}"; do
        [ -f "${file}" ]
    done

    symbolic_links_exists=(
        "~/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json"
    )
    for link in "${symbolic_links_exists[@]}"; do
        [ -L "${link}" ]
    done

    files_not_exists=(
        "~/.local/bin/server"
        "~/.zsh/server/zshrc"
        "~/.zsh/server/zprofile"
        "~/.tmux.conf.d/system/server.conf"
        "~/.tmux.conf.d/os/ubuntu_client.conf"
    )
    for file in "${files_not_exists[@]}"; do
        [ ! -f "${file}" ]
    done
}
