#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/dependencies.sh"

@test "[ubuntu-common] PACKAGES for dependencies" {
    run bash -c '
        source "'"${SCRIPT_PATH}"'"
        printf "%s\n" "${#PACKAGES[@]}"
        printf "%s\n" "${PACKAGES[@]}"
    '

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" -eq 13 ]

    expected_packages=(
        busybox
        cmake
        curl
        git
        gpg
        htop
        iproute2
        iputils-ping
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

@test "[ubuntu-common] install_apt_packages includes all non-sudo packages in apt install args" {
    run bash -c '
        set +x
        unset DOTFILES_DEBUG
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
    actual_output="${output}"

    run bash -c '
        source "'"${SCRIPT_PATH}"'"

        install_targets=()
        for package in "${PACKAGES[@]}"; do
            if [ "${package}" != "sudo" ]; then
                install_targets+=("${package}")
            fi
        done

        printf "%s\n" "--preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y ${install_targets[*]}"
    '
    [ "${status}" -eq 0 ]
    [ "${actual_output}" = "${output}" ]
}

@test "[ubuntu-common] install_apt_packages exits early when nothing is missing" {
    run bash -c '
        set +x
        unset DOTFILES_DEBUG
        source "'"${SCRIPT_PATH}"'"
        command() {
            if [ "$1" = "-v" ]; then
                return 0
            fi
            builtin command "$@"
        }
        sudo() {
            printf "unexpected:%s\n" "$*"
        }

        install_apt_packages
    '

    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
