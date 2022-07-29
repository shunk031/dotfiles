#!/usr/bin/env bash

function exec_common_init() {
    for f in "$DOTPATH"/etc/init/common/*.sh; do
        bash "$f"
    done
}

function exec_mac_os_init() {
    os="$1"
    arch="$(get_cpu_arch)"

    for f in "$DOTPATH"/etc/init/gui/"$os"/"$arch"/*sh; do
        bash "$f"
    done
}

function exec_ubuntu_init() {
    local os="$1"

    for f in "$DOTPATH"/etc/init/gui/linux/"$os"/*sh; do
        bash "$f"
    done
}

function exec_specific_os_init() {
    # Convert to the $1 argument to lower case
    ui=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    if [ "$ui" != "gui" ] && [ "$ui" != "cui" ]; then
        echo "The ui option is \`gui\` or \`cui\` only. But got \`$1\`." >&2
        exit 1
    fi

    os="$(get_os)"
    if [ "$os" == "macos" ]; then
        exec_mac_os_init "$os"
    elif [ "$os" == "ubuntu" ]; then
        exec_ubuntu_init "$os"
    else
        echo "Unknown OS: $os."
        exit 1
    fi
}

function install_cmd() {

    . "$DOTPATH"/etc/lib/install_utils.sh

    exec_common_init
    exec_specific_os_init "$1"
}
