#!/usr/bin/env bash

# @file install/macos/common/command_line_tool.sh
# @brief Xcode Command Line Tools installation script
# @description
#   This script installs the Xcode Command Line Tools, which provide
#   essential development utilities like git, clang, and make for macOS.

set -Eeuo pipefail

if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi

# @description Install Xcode Command Line Tools
# @exitcode 0 On success or if tools are already installed
# @exitcode 1 If installation fails
# @example
#   install_command_line_tool
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

# @description Main entry point for the Xcode Command Line Tools installation script
# @exitcode 0 On success
# @exitcode 1 On failure
# @example
#   ./command_line_tool.sh
function main() {
    install_command_line_tool
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
