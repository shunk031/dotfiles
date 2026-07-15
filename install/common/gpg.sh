#!/usr/bin/env bash

# @file install/common/gpg.sh
# @brief Warm up the GPG signing cache for git commits.
# @description
#   Prompts for the GPG signing passphrase in interactive installs so later
#   signed git commits can reuse the long-lived gpg-agent cache.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Check whether the script is running in CI.
#
function is_ci() {
    [ "${CI:-false}" = "true" ]
}

#
# @description Check whether stdin is an interactive terminal.
#
function is_interactive_tty() {
    [ -t 0 ]
}

#
# @description Check whether git commit signing is enabled.
#
function is_git_commit_signing_enabled() {
    local gpgsign

    if ! command -v git > /dev/null 2>&1; then
        return 1
    fi

    if ! gpgsign="$(git config --get --bool commit.gpgsign 2> /dev/null)"; then
        return 1
    fi

    [ "${gpgsign}" = "true" ]
}

#
# @description Print the configured git signing key when one is available.
#
function get_git_signing_key() {
    if ! command -v git > /dev/null 2>&1; then
        return 0
    fi

    git config --get user.signingkey 2> /dev/null || true
}

#
# @description Reload gpg-agent so the applied gpg-agent config is active.
#
function reload_gpg_agent() {
    if command -v gpgconf > /dev/null 2>&1; then
        gpgconf --reload gpg-agent > /dev/null 2>&1 || true
    fi
}

#
# @description Run a small signing operation to populate the gpg-agent cache.
#
function warmup_gpg_signing_cache() {
    local signing_key
    signing_key="$(get_git_signing_key)"

    reload_gpg_agent

    if [ -t 0 ]; then
        export GPG_TTY
        GPG_TTY="$(tty)"
    fi

    if [ -n "${signing_key}" ]; then
        printf "dotfiles gpg signing cache warm-up\n" |
            gpg --local-user "${signing_key}" --clearsign > /dev/null
    else
        printf "dotfiles gpg signing cache warm-up\n" |
            gpg --clearsign > /dev/null
    fi
}

#
# @description Run the GPG signing cache warm-up when the environment supports it.
#
function main() {
    if is_ci; then
        echo "Skipping GPG signing cache warm-up in CI."
        return 0
    fi

    if ! is_interactive_tty; then
        echo "Skipping GPG signing cache warm-up because stdin is not a TTY."
        return 0
    fi

    if ! command -v gpg > /dev/null 2>&1; then
        echo "Warning: gpg is not installed. Skipping GPG signing cache warm-up." >&2
        return 0
    fi

    if ! is_git_commit_signing_enabled; then
        echo "Skipping GPG signing cache warm-up because commit.gpgsign is not true."
        return 0
    fi

    echo "Warming up GPG signing cache. This may prompt for your GPG passphrase."
    if ! warmup_gpg_signing_cache; then
        echo "Warning: Failed to warm up GPG signing cache. Continuing install." >&2
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
