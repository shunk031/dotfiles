#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TMUX_PLUGINS_DIR="${HOME%/}/.tmux/plugins"
readonly TPM_DIR="${TMUX_PLUGINS_DIR}/tpm"

function is_tmux_mem_cpu_load_installed() {
    command -v "tmux-mem-cpu-load" &>/dev/null
}

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
    export TMUX_PLUGIN_MANAGER_PATH="${TMUX_PLUGINS_DIR}"

    if [ ! "${DOTFILES_DEBUG:-}" ] || [ ! -d "${TPM_DIR}" ]; then
        clone_tpm "${TPM_DIR}"
        install_tpm_plugins "${TPM_DIR}"
    fi
}

function install_tmux_mem_cpu_load() {
    if [ ! "${DOTFILES_DEBUG:-}" ] && is_tmux_mem_cpu_load_installed; then
        return 0 # early return
    fi

    local tmux_mem_cpu_load_url="https://github.com/thewtex/tmux-mem-cpu-load.git"

    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/tmux-mem-cpu-load-XXXXXXXXXX)"

    git clone "${tmux_mem_cpu_load_url}" "${tmp_dir}"
    cd "${tmp_dir}" || exit 1
    cmake . -DCMAKE_INSTALL_PREFIX="${HOME%/}/.local/"
    make
    make install
}

function uninstall_tpm() {
    rm -rfv "${TPM_DIR}"
}

function uninstall_tmux_mem_cpu_load() {
    rm -fv "${HOME%/}/.local/bin/tmux-mem-cpu-load"
}

function main() {
    install_tpm
    install_tmux_mem_cpu_load
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
