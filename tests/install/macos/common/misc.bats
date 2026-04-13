#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/misc.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

@test "[macos] misc" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    #
    # brew packages
    #
    run brew info gpg
    [ "${status}" -eq 0 ]
    run brew info imagemagick
    [ "${status}" -eq 0 ]
    run brew info htop
    [ "${status}" -eq 0 ]
    run brew info pinentry-mac
    [ "${status}" -eq 0 ]
    run brew info tailscale
    [ "${status}" -eq 0 ]
    run brew info vim
    [ "${status}" -eq 0 ]
    run brew info watchexec
    [ "${status}" -eq 0 ]
    run brew info zsh
    [ "${status}" -eq 0 ]

    #
    # Cask packages
    #

    # Currently, we do not run this test on CI
    # because of the time it takes to install the cask packages.
}

@test "[macos] install_additional_brew_packages installs tailscale only for shunk031" {
    local calls_path="${BATS_TEST_TMPDIR}/additional_brew_calls.txt"
    : > "${calls_path}"

    run env CALLS_PATH="${calls_path}" CI=false bash -c '
        source "'"${SCRIPT_PATH}"'"

        whoami() {
            echo "shunk031"
        }

        is_brew_package_installed() {
            return 1
        }

        brew() {
            echo "$*" >> "${CALLS_PATH}"
        }

        install_additional_brew_packages
    '

    [ "${status}" -eq 0 ]

    run cat "${calls_path}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "install --force tailscale" ]
}

@test "[macos] install_additional_brew_packages skips tailscale for other users" {
    local calls_path="${BATS_TEST_TMPDIR}/additional_brew_calls_other_user.txt"
    : > "${calls_path}"

    run env CALLS_PATH="${calls_path}" CI=false bash -c '
        source "'"${SCRIPT_PATH}"'"

        whoami() {
            echo "s.kitada"
        }

        is_brew_package_installed() {
            return 1
        }

        brew() {
            echo "$*" >> "${CALLS_PATH}"
        }

        install_additional_brew_packages
    '

    [ "${status}" -eq 0 ]
    [ ! -s "${calls_path}" ]
}
