#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function is_formula_installed() {
    local formula="$1"
    brew ls --versions "${formula}" >/dev/null
}

function is_cask_formula_installed() {
    local formula="$1"
    brew ls --cask --versions "${formula}" >/dev/null
}

function install_brew_packages() {
    local packages=(
        "exa"
        "imagemagick"
        "jq"
        "hugo"
        "htop"
        "shellcheck"
        "tailscale"
        "vim"
        "watchexec"
        "zsh"
    )
    for package in "${packages[@]}"; do
        if "${CI:-false}"; then
            brew info "${package}"
        else
            if ! is_formula_installed "${package}"; then
                brew install "${package}"
            fi
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
            brew info --cask "${package}"
        else
            if ! is_cask_formula_installed "${package}"; then
                brew install --cask "${package}"
            fi
        fi
    done
}

function setup_google_chrome() {
    open "/Applications/Google Chrome.app" --args --make-default-browser
}

function main() {
    install_brew_packages
    install_brew_cask_packages

    # setup_spectacle
    # setup_google_chrome
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
