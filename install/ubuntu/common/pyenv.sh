#!/usr/bin/env bash

set -Eeuox pipefail

function install_pyenv_requirements() {
    sudo apt-get install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        curl \
        llvm \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev
}

function main() {
    install_pyenv_requirements
}

if [ ${#BASH_SOURCE[@]} = 1 ]; then
    main
fi
