#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/dependencies.sh"

@test "[ubuntu-common] PACKAGES for dependencies" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"
        printf "%s\n" "${#PACKAGES[@]}"
        printf "%s\n" "${PACKAGES[@]}"
    '

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" -eq 11 ]

    expected_packages=(
        busybox
        curl
        git
        gpg
        htop
        iproute2
        sudo
        unzip
        vim
        wget
        zsh
    )

    for ((i = 0; i < ${#expected_packages[*]}; ++i)); do
        [ "${lines[$((i + 1))]}" = "${expected_packages[$i]}" ]
    done
}

@test "[ubuntu-common] install_apt_packages includes iproute2 in apt install args" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"
        command() {
            if [ "$1" = "-v" ] && [ "$2" = "sudo" ]; then
                return 0
            fi
            if [ "$1" = "-v" ]; then
                return 1
            fi
            builtin command "$@"
        }
        sudo() {
            printf "%s\n" "$*"
        }

        install_apt_packages
    '

    [ "${status}" -eq 0 ]
    [ "${output}" = "--preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y busybox curl git gpg htop iproute2 unzip vim wget zsh" ]
}
