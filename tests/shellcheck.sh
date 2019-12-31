#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && source "../install/util.sh"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {
    find \
        ../install \
        ../tests \
        -type f \
        -exec shellcheck \
        -e SC1090 \
        -e SC1091 \
        -e SC2155 \
        -e SC2164 \
        {} +

    print_result $? "Run code through ShellCheck"

}

main
