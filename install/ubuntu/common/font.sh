#!/usr/bin/env bash

set -Eeuox pipefail

function install_nerd_font() {
    local font_url="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Medium/complete/Roboto%20Mono%20Medium%20Nerd%20Font%20Complete%20Mono.ttf"
    local font_dir="${HOME%/}/.local/share/fonts"
    local font_name="Roboto Mono Nerd Font Complete.ttf"

    mkdir -p "${font_dir}"
    curl -fSL "${font_url}" -o "${font_dir%/}/${font_name}"
}

function main() {
    install_nerd_font
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
