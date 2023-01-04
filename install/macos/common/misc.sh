#!/usr/bin/env bash

set -Eeuox pipefail

function install_brew_packages() {
    local packages=(
        "exa"
        "jq"
        "hugo"
        "htop"
        "shellcheck"
        "tailscale"
        "vim"
        "zsh"
    )
    for package in "${packages[@]}"; do
        if "${CI:-false}"; then
            brew info "${package}"
        else
            brew install "${package}"
        fi
    done
}

function install_brew_cask_packages() {
    local packages=(
        "adobe-acrobat-reader"
        "google-chrome"
        "google-drive"
        "google-japanese-ime"
        "slack"
        "spectacle"
        "spotify"
        "vlc"
        "visual-studio-code"
        "zotero"
        "zoom"
    )
    for package in "${packages[@]}"; do
        if ${CI:-false}; then
            brew info "${package}"
        else
            brew install --cask "${package}"
        fi
    done
}

function setup_spectacle() {
    open /Applications/Spectacle.app/
}

function main() {
    install_brew_packages
    install_brew_cask_packages

    setup_spectacle
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
