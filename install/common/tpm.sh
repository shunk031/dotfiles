#!/usr/bin/env bash

set -Eeuox pipefail

function clone_tpm() {
    local dir="$1"
    local url="https://github.com/tmux-plugins/tpm"

    if [ ! -d "${dir}" ]; then
        git clone "${url}" "${dir}"
    fi
}

function install_tpm_plugins() {
    local dir="$1"
    local cmd="${dir%/}/scripts/install_plugins.sh"

    "${cmd}"
}

function install_tpm() {
    export TMUX_PLUGIN_MANAGER_PATH="${HOME%/}/.tmux/plugins"

    local dir="${TMUX_PLUGIN_MANAGER_PATH%/}/tpm/"

    clone_tpm "${dir}"
    install_tpm_plugins "${dir}"
}

function install_tmux_mem_cpu_load() {
    local tmux_mem_cpu_load_url="https://github.com/thewtex/tmux-mem-cpu-load.git"

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/tmux-mem-cpu-load-XXXXXXXXXX)"

    git clone "${tmux_mem_cpu_load_url}" "${tmp_dir}"
    cd "${tmp_dir}" || exit 1
    cmake . -DCMAKE_INSTALL_PREFIX="${HOME%/}/.local/"
    make
    make install
}

function main() {

    install_tpm
    install_tmux_mem_cpu_load
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
