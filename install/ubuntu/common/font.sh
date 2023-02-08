#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function install_font() {
    local font_url="$1"
    local font_name="$2"

    local font_dir="${HOME%/}/.local/share/fonts"

    mkdir -p "${font_dir}"
    curl -fSL "${font_url}" -o "${font_dir%/}/${font_name}"
}

function install_nerd_font_roboto_mono() {
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Medium/complete/Roboto%20Mono%20Medium%20Nerd%20Font%20Complete%20Mono.ttf"
    local font_name="Roboto Mono Nerd Font Complete.ttf"

    install_font "${font_url}" "${font_name}"
}

function install_nerd_font_hack_mono() {
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/complete/Hack%20Regular%20Nerd%20Font%20Complete%20Mono.ttf"
    local font_name="Hack Regular Nerd Font Complete Mono.ttf"

    install_font "${font_url}" "${font_name}"
}

function main() {
    install_nerd_font_roboto_mono
    install_nerd_font_hack_mono
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
