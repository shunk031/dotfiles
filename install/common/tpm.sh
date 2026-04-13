#!/usr/bin/env bash

# @file install/common/tpm.sh
# @brief Install tmux plugin tooling.
# @description
#   Clones TPM, installs tmux plugins, and builds `tmux-mem-cpu-load` into the
#   user's local prefix.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly TMUX_PLUGINS_DIR="${HOME%/}/.tmux/plugins"
readonly TPM_DIR="${TMUX_PLUGINS_DIR}/tpm"

#
# @description Check whether `tmux-mem-cpu-load` is already installed.
#
function is_tmux_mem_cpu_load_installed() {
    command -v "tmux-mem-cpu-load" &> /dev/null
}

#
# @description Clone the TPM repository when it is not present.
# @arg $1 path Target directory for the TPM checkout.
#
function clone_tpm() {
    local dir="$1"
    local url="https://github.com/tmux-plugins/tpm"

    if [ ! -d "${dir}" ]; then
        git clone "${url}" "${dir}"
    fi
}

#
# @description Run TPM's plugin installer in a nounset-safe subshell.
# @arg $1 path TPM installation directory.
#
function install_tpm_plugins() {
    local dir="$1"
    local cmd="${dir%/}/scripts/install_plugins.sh"

    (
        # `bashcov` can affect shell option propagation while tracing scripts.
        # TPM helper scripts reference positional parameters directly (`$1`)
        # and fail under nounset; run installer in a subshell with `set +u`
        # to keep parent strict mode while preserving TPM script compatibility.
        set +u
        "${cmd}"
    )
}

#
# @description Install TPM and fetch tmux plugins.
#
function install_tpm() {
    export TMUX_PLUGIN_MANAGER_PATH="${TMUX_PLUGINS_DIR}"

    if [ ! "${DOTFILES_DEBUG:-}" ] || [ ! -d "${TPM_DIR}" ]; then
        clone_tpm "${TPM_DIR}"
        install_tpm_plugins "${TPM_DIR}"
    fi
}

#
# @description Build and install `tmux-mem-cpu-load` from source.
#
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

#
# @description Remove the TPM checkout.
#
function uninstall_tpm() {
    rm -rfv "${TPM_DIR}"
}

#
# @description Remove the installed `tmux-mem-cpu-load` binary.
#
function uninstall_tmux_mem_cpu_load() {
    rm -fv "${HOME%/}/.local/bin/tmux-mem-cpu-load"
}

#
# @description Install TPM and `tmux-mem-cpu-load`.
#
function main() {
    install_tpm
    install_tmux_mem_cpu_load
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
