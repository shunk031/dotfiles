#!/usr/bin/env bash

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

function main() {
    export TZ="Asia/Tokyo"
    sudo ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
    echo "${TZ}" | sudo tee /etc/timezone

    DEBIAN_FRONTEND="noninteractive" sudo --preserve-env=http_proxy,https_proxy,no_proxy apt-get install -y tzdata
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
