#!/usr/bin/env bash

# @file install/ubuntu/server/starship.sh
# @brief Install the Starship prompt on Ubuntu servers.
# @description
#   Downloads the upstream Starship installer and places the binary in the
#   user's local bin directory.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

#
# @description Download and install the Starship binary.
#
function install_starship() {
    # equivalent to `https://starship.rs/install.sh`
    local url="https://raw.githubusercontent.com/starship/starship/master/install/install.sh"
    local version="latest"

    mkdir -p "${BIN_DIR}"

    curl -sS "${url}" | dash -s -- \
        --yes \
        --version "${version}" \
        --bin-dir "${BIN_DIR}"
}

#
# @description Remove the locally installed Starship binary directory.
#
function uninstall_starship() {
    rm -rf "${BIN_DIR}"
}

#
# @description Run the Starship installation flow.
#
function main() {
    install_starship
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
