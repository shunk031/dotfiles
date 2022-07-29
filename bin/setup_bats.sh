#!/usr/bin/env bash

set -eux

function install_git() {
    sudo apt-get update && sudo apt-get install -y git
}

function install_bats() {
    declare -r BATS_VERSION=v1.3.0
    declare -r BASTS_URL=https://github.com/bats-core/bats-core.git
    declare -r BATS_DIR=$HOME/bats-core

    rm -rf BATS_DIR
    git clone --depth 1 --branch "$BATS_VERSION" "$BASTS_URL" "$BATS_DIR"
    export PATH="$PATH":"$HOME"/bats-core/bin
}

install_git
install_bats
