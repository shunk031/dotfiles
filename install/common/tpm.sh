#!/usr/bin/env bash

# @file install/common/tpm.sh
# @brief TPM (Tmux Plugin Manager) installation script
# @description
#   This script installs TPM (Tmux Plugin Manager) and its plugins,
#   along with the tmux-mem-cpu-load utility for system monitoring.
#   It handles cloning the TPM repository and installing all configured plugins.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TMUX_PLUGINS_DIR="${HOME%/}/.tmux/plugins"
readonly TPM_DIR="${TMUX_PLUGINS_DIR}/tpm"

# @description Check if tmux-mem-cpu-load command is available in PATH
# @exitcode 0 If tmux-mem-cpu-load is installed
# @exitcode 1 If tmux-mem-cpu-load is not installed
function is_tmux_mem_cpu_load_installed() {
    command -v "tmux-mem-cpu-load" &>/dev/null
}

# @description Clone TPM repository to the specified directory
# @arg $1 string Target directory path for TPM installation
# @exitcode 0 On successful clone or if directory already exists
# @exitcode 1 If git clone fails
# @example
#   clone_tpm "${HOME}/.tmux/plugins/tpm"
function clone_tpm() {
    local dir="$1"
    local url="https://github.com/tmux-plugins/tpm"

    if [ ! -d "${dir}" ]; then
        git clone "${url}" "${dir}"
    fi
}

# @description Install all TPM plugins using the TPM install script
# @arg $1 string TPM directory path
# @exitcode 0 On successful installation
# @exitcode 1 If installation fails
# @example
#   install_tpm_plugins "${HOME}/.tmux/plugins/tpm"
function install_tpm_plugins() {
    local dir="$1"
    local cmd="${dir%/}/scripts/install_plugins.sh"

    "${cmd}"
}

# @description Install TPM (Tmux Plugin Manager) and its plugins
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   install_tpm
function install_tpm() {
    export TMUX_PLUGIN_MANAGER_PATH="${TMUX_PLUGINS_DIR}"

    if [ ! "${DOTFILES_DEBUG:-}" ] || [ ! -d "${TPM_DIR}" ]; then
        clone_tpm "${TPM_DIR}"
        install_tpm_plugins "${TPM_DIR}"
    fi
}

# @description Install tmux-mem-cpu-load system monitoring utility
# @exitcode 0 On success or if already installed (in non-debug mode)
# @exitcode 1 If installation fails
# @example
#   install_tmux_mem_cpu_load
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

# @description Uninstall TPM by removing its directory
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_tpm
function uninstall_tpm() {
    rm -rfv "${TPM_DIR}"
}

# @description Uninstall tmux-mem-cpu-load by removing the binary
# @exitcode 0 On successful removal
# @exitcode 1 If removal fails
# @example
#   uninstall_tmux_mem_cpu_load
function uninstall_tmux_mem_cpu_load() {
    rm -fv "${HOME%/}/.local/bin/tmux-mem-cpu-load"
}

# @description Main entry point for the TPM installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./tpm.sh
function main() {
    install_tpm
    install_tmux_mem_cpu_load
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
