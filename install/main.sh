#!/bin/bash

# cd "$(dirname "${BASH_SOURCE[0]}")" \
#     && . "../utils.sh"

. "install/util.sh" || exit 1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

print_in_purple "\n • Installs\n"

bash "./install/$(get_os)/main.sh"
