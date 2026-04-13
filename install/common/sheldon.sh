#!/usr/bin/env bash

# @file install/common/sheldon.sh
# @brief Install the Sheldon shell plugin manager.
# @description
#   Downloads the latest `sheldon` binary into the user's local bin directory.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly BIN_DIR="${HOME}/.local/bin"

#
# @description Download and install `sheldon` into `BIN_DIR`.
#
function install_sheldon() {
    mkdir -p "${BIN_DIR}"

    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh |
        bash -s -- --repo rossmacarthur/sheldon --to "${BIN_DIR}" --force
}

#
# @description Remove the installed `sheldon` binary.
#
function uninstall_sheldon() {
    rm "${BIN_DIR}/sheldon"
}

#
# @description Run the Sheldon installation flow.
#
function main() {
    install_sheldon
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
