#!/usr/bin/env bash

# @file install/macos/common/command_line_tool.sh
# @brief Install Xcode Command Line Tools.
# @description
#   Triggers the Apple command line tools installer and waits for the user to
#   confirm the installation has completed.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

#
# @description Install Xcode Command Line Tools when `git` is not available.
#
function install_command_line_tool() {
    local git_cmd_path="/Library/Developer/CommandLineTools/usr/bin/git"

    if [ ! -e "${git_cmd_path}" ]; then
        # Install command line developer tool
        xcode-select --install
        # Want for user input
        echo "Press any key when the installation has completed."
        IFS= read -r -n 1 -d ''
        #          │  │    └ The first character of DELIM is used to terminate the input line, rather than newline.
        #          │  │
        #          │  └ returns after reading NCHARS characters rather than waiting for a complete line of input.
        #          │
        #          └ If this option is given, backslash does not act as an escape character.
        #            The backslash is considered to be part of the line. In particular, a backslash-newline
        #            pair may not be used as a line continuation.
    else
        echo "Command line developer tools are installed."
    fi
}

#
# @description Run the command line tools installation flow.
#
function main() {
    install_command_line_tool
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
