#!/usr/bin/env bats

load etc/install.sh

function setup() {
    export DOTPATH="."
}

@test "test for get_os" {
    uname() {
        echo "macos"
    }
    result="$(get_os)"
    [ $result = "macos" ]

    uname() {
        echo "ubuntu"
    }
    result="$(get_os)"
    [ $result = "ubuntu" ]
}

@test "test for get_cpu_arch" {
    result="$(get_cpu_arch)"
    [ $result = "aarch64" ]
}

@test "test for install_cmd with GUI option" {
    install_cmd "gui"
}

@test "test for install_cmd with CUI option" {
    install_cmd "cui"
}
