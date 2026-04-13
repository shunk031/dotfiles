#!/usr/bin/env bash

# @file install/common/gh_extensions.sh
# @brief Install GitHub CLI extensions used by the dotfiles.
# @description
#   Activates `mise` when available, ensures GitHub authentication, and
#   installs the configured `gh` extensions.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly MISE_BIN="${HOME}/.local/bin/mise"

readonly GH_EXTENSIONS=(
    seachicken/gh-poi
)

#
# @description Activate `mise` so `gh` can resolve the expected toolchain.
#
function activate_mise() {
    if [ -x "${MISE_BIN}" ]; then
        eval "$("${MISE_BIN}" activate bash)"
    fi
}

#
# @description Prompt for GitHub CLI authentication when no session exists.
#
function ensure_gh_auth() {
    if ! gh auth status &> /dev/null; then
        gh auth login -h github.com -p https
    fi
}

#
# @description Install every extension listed in `GH_EXTENSIONS`.
#
function install_gh_extensions() {
    for extension in "${GH_EXTENSIONS[@]}"; do
        gh extension install "${extension}"
    done
}

#
# @description Run the `gh` extension installation workflow.
#
function main() {
    activate_mise
    ensure_gh_auth
    install_gh_extensions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
