#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/ubuntu/common/ssh.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_openssh
}

@test "[ubuntu-common] PACKAGES for ssh" {
    [ ${#PACKAGES[@]} -eq 1 ]
}

@test "[ubuntu-common] ssh" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    run dpkg -s 'openssh-client'
    [ "${status}" -eq 0 ]
}

@test "[ubuntu-common] uninstall_openssh issues apt remove" {
    run bash -c '
        set +x
        unset DOTFILES_DEBUG
        source "'"${SCRIPT_PATH}"'"
        set +x
        sudo() {
            printf "%s\n" "$*"
        }

        uninstall_openssh
    '

    [ "${status}" -eq 0 ]
    [[ "${output}" == *"apt-get remove -y openssh-client"* ]]
}
