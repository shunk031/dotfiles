#!/usr/bin/env bash

# set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

export MISE_INSTALL_PATH="${HOME}/.local/bin/mise"
readonly DEFAULT_NPM_MIN_RELEASE_AGE_DAYS=7

function install_mise() {
    # https://mise.run
    local version="v2026.3.7"
    local url="https://raw.githubusercontent.com/jdx/mise/refs/tags/${version}/packaging/standalone/install.envsubst"

    export MISE_CURRENT_VERSION="${version}"
    curl "${url}" | sh
    unset MISE_CURRENT_VERSION

    eval "$(~/.local/bin/mise activate bash)"
}

function run_mise_install() {
    # `MISE_CURRENT_VERSION` is interpreted by mise as a tool env override for `current`.
    unset MISE_CURRENT_VERSION

    local npm_min_release_age_days
    npm_min_release_age_days="$(awk -F= '
        $1 ~ /^[[:space:]]*min-release-age[[:space:]]*$/ {
            gsub(/[[:space:]]/, "", $2)
            print $2
            exit
        }
    ' "${HOME}/.npmrc" 2> /dev/null || true)"

    if [[ -z "${npm_min_release_age_days}" ]] || ! [[ "${npm_min_release_age_days}" =~ ^[0-9]+$ ]]; then
        npm_min_release_age_days="${DEFAULT_NPM_MIN_RELEASE_AGE_DAYS}"
    fi

    mise install --before "${npm_min_release_age_days}d"
}

function uninstall_mise() {
    rm "${MISE_INSTALL_PATH}"
}

function main() {
    install_mise
    run_mise_install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
