#!/usr/bin/env bats

# @test "[macos] dotfiles" {
#     files_exists=(
#         "${HOME}/.config/powerlevel10k/p10k.zsh"
#         "${HOME}/.zsh/client/zshrc"
#         "${HOME}/.zsh/client/zprofile"
#         "${HOME}/.bash/client/bashrc"
#         "${HOME}/.tmux-powerlinerc"
#         "${HOME}/.tmux.conf.d/system/client.conf"
#         "${HOME}/.tmux.conf.d/os/macos.conf"
#     )
#     for file in "${files_exists[@]}"; do
#         echo "Checking ${file}"
#         [ -f "${file}" ]
#     done

#     directories_exists=(
#         "${HOME}/.local/bin/client"
#         "${HOME}/.zprezto"
#     )
#     for directory in "${directories_exists[@]}"; do
#         echo "Checking ${directory}"
#         [ -d "${directory}" ]
#     done

#     symbolic_links_exists=(
#         "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/hotkey_window.json"
#     )
#     for link in "${symbolic_links_exists[@]}"; do
#         echo "Checking ${link}"
#         [ -L "${link}" ]
#     done

#     files_not_exists=(
#         "${HOME}/.local/bin/server"
#         "${HOME}/.zsh/server/zshrc"
#         "${HOME}/.zsh/server/zprofile"
#         "${HOME}/.tmux.conf.d/system/server.conf"
#         "${HOME}/.tmux.conf.d/os/ubuntu_client.conf"
#     )
#     for file in "${files_not_exists[@]}"; do
#         echo "Checking ${file}"
#         [ ! -f "${file}" ]
#     done
# }
