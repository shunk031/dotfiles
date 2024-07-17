#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function main() {
    export TZ="Asia/Tokyo"
    sudo ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone

    DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y tzdata
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
