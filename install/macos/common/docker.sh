#!/usr/bin/env bash

# @file install/macos/common/docker.sh
# @brief Remove Docker Desktop from macOS.
# @description
#   Stops Docker Desktop, removes the Homebrew cask when present, and clears
#   stale Docker Desktop helper links.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

readonly DOCKER_DESKTOP_CASK_TOKENS=(
    docker-desktop
    docker
)
readonly DOCKER_DESKTOP_HELPER_LINKS=(
    /usr/local/bin/docker
    /usr/local/bin/docker-credential-desktop
    /usr/local/bin/docker-credential-ecr-login
    /usr/local/bin/docker-credential-osxkeychain
    /usr/local/bin/hub-tool
    /usr/local/bin/kubectl.docker
    /usr/local/cli-plugins/docker-compose
)

#
# @description Check whether a Homebrew cask is installed.
# @arg $1 string Homebrew cask token.
#
function is_cask_installed() {
    local cask_token="$1"

    brew list --cask "${cask_token}" &> /dev/null
}

#
# @description Stop Docker Desktop if the application helper is available.
#
function stop_docker_desktop() {
    if [ -x "/Applications/Docker.app/Contents/MacOS/com.docker.backend" ]; then
        "/Applications/Docker.app/Contents/MacOS/com.docker.backend" -quit || true
    fi

    osascript -e 'quit app "Docker"' &> /dev/null || true
}

#
# @description Remove Docker Desktop Homebrew casks installed under known tokens.
#
function uninstall_docker_desktop() {
    local cask_token

    for cask_token in "${DOCKER_DESKTOP_CASK_TOKENS[@]}"; do
        if is_cask_installed "${cask_token}"; then
            brew uninstall --cask "${cask_token}" --force
        fi
    done
}

#
# @description Remove stale Docker Desktop helper symlinks.
#
function remove_docker_desktop_helper_links() {
    local helper_link

    for helper_link in "${DOCKER_DESKTOP_HELPER_LINKS[@]}"; do
        if [ -L "${helper_link}" ]; then
            rm -f "${helper_link}"
        fi
    done
}

#
# @description Remove the Docker Desktop application bundle when it remains.
#
function remove_docker_desktop_app_bundle() {
    if [ -d "/Applications/Docker.app" ]; then
        rm -rf "/Applications/Docker.app"
    fi
}

#
# @description Remove Docker Desktop from this macOS host.
#
function remove_docker_desktop() {
    stop_docker_desktop
    uninstall_docker_desktop
    remove_docker_desktop_helper_links
    remove_docker_desktop_app_bundle
}

#
# @description Run the Docker Desktop removal flow.
#
function main() {
    remove_docker_desktop
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
