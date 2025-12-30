#!/usr/bin/env bats

# # bats test_tags=ubuntu:client
# @test "[ubuntu-client] dotfiles" {
#     files_exists=(
#         "${HOME}/.zsh/client/zshrc"
#         "${HOME}/.zsh/client/zprofile"
#         "${HOME}/.tmux-powerlinerc"
#         "${HOME}/.tmux.conf.d/system/client.conf"
#         "${HOME}/.tmux.conf.d/os/ubuntu_client.conf"
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

#     files_not_exists=(
#         "${HOME}/.zsh/server/zshrc"
#         "${HOME}/.zsh/server/zprofile"
#         "${HOME}/.tmux.conf.d/system/server.conf"
#         "${HOME}/.tmux.conf.d/os/macos.conf"
#     )
#     for file in "${files_not_exists[@]}"; do
#         echo "Checking ${file}"
#         [ ! -f "${file}" ]
#     done
# }

# # bats test_tags=ubuntu:server
# @test "[ubuntu-server] dotfiles" {
#     files_exists=(
#         "${HOME}/.zsh/server/zshrc"
#         "${HOME}/.zsh/server/zprofile"
#         "${HOME}/.tmux.conf.d/system/server.conf"
#         "${HOME}/.tmux.conf.d/os/ubuntu_server.conf"
#     )
#     for file in "${files_exists[@]}"; do
#         echo "Checking ${file}"
#         [ -f "${file}" ]
#     done

#     files_not_exists=(
#         "${HOME}/.tmux-powerlinerc"
#         "${HOME}/.zsh/client/zshrc"
#         "${HOME}/.zsh/client/zprofile"
#         "${HOME}/.tmux.conf.d/system/client.conf"
#         "${HOME}/.tmux.conf.d/os/macos.conf"
#     )
#     for file in "${files_not_exists[@]}"; do
#         echo "Checking ${file}"
#         [ ! -f "${file}" ]
#     done
# }
