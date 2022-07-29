#!/usr/bin/env bash

function get_os() {
    local os=""
    local kernel_name=""

    kernel_name="$(uname -s)"

    if [ "$kernel_name" == "Darwin" ]; then
        os="macos"
    elif [ "$kernel_name" == "Linux" ] &&
        [ -e "/etc/os-release" ]; then
        # shellcheck disable=SC1091
        os="$(
            . /etc/os-release
            printf "%s" "$ID"
        )"
    else
        os="$kernel_name"
    fi

    printf "%s" "$os"
}

function get_cpu_arch() {
    machine_arch_name="$(uname -m)"
    printf "%s" "$machine_arch_name"
}

function get_os_version() {
    local os=""
    local version=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    os="$(get_os)"

    if [ "$os" == "macos" ]; then
        version="$(sw_vers -productVersion)"
    elif [ -e "/etc/os-release" ]; then
        # shellcheck disable=SC1091
        version="$(
            . /etc/os-release
            printf "%s" "$VERSION_ID"
        )"
    fi

    printf "%s" "$version"
}

function execute() {

    local -r CMDS="$1"
    local -r MSG="${2:-$1}"
    local -r TMP_FILE="$(mktemp /tmp/XXXXX)"

    local exit_code=0
    local cmds_PID=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # If the current process is ended,
    # also end all its subprocesses.

    set_trap "EXIT" "kill_all_subprocesses"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Execute commands in background
    # shellcheck disable=SC2261
    eval "$CMDS" \
        &>/dev/null \
        2>"$TMP_FILE" &

    cmds_PID=$!

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Show a spinner if the commands
    # require more time to complete.

    show_spinner "$cmds_PID" "$CMDS" "$MSG"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait for the commands to no longer be executing
    # in the background, and then get their exit code.

    wait "$cmds_PID" &>/dev/null
    exit_code=$?

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Print output based on what happened.

    print_result $exit_code "$MSG"

    if [ $exit_code -ne 0 ]; then
        print_error_stream <"$TMP_FILE"
    fi

    rm -rf "$TMP_FILE"

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    return $exit_code
}

function mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1"
            fi
        else
            execute "mkdir -p $1" "$1"
        fi
    fi
}

function print_error() {
    print_in_red "   [✖] $1 $2\n"
}

function print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

function print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2>/dev/null)" \
        "$1" \
        "$(tput sgr0 2>/dev/null)"
}

function print_in_green() {
    print_in_color "$1" 2
}

function print_in_purple() {
    print_in_color "$1" 5
}

function print_in_red() {
    print_in_color "$1" 1
}

function print_in_yellow() {
    print_in_color "$1" 3
}

function print_question() {
    print_in_yellow "   [?] $1"
}

function print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"
}

function print_success() {
    print_in_green "   [✔] $1\n"
}

function print_warning() {
    print_in_yellow "   [!] $1\n"
}

function set_trap() {
    trap -p "$1" | grep "$2" &>/dev/null ||
        trap '$2' "$1"
}

show_spinner() {
    local -r FRAMES='/-\|'

    # shellcheck disable=SC2034
    local -r NUMBER_OR_FRAMES=${#FRAMES}

    local -r CMDS="$2"
    local -r MSG="$3"
    local -r PID="$1"

    local i=0
    local frame_text=""

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Note: In order for the Travis CI site to display
    # things correctly, it needs special treatment, hence,
    # the "is Travis CI?" checks.

    if [ "$GITHUB_ACTIONS" != "true" ]; then

        # Provide more space so that the text hopefully
        # doesn't reach the bottom line of the terminal window.
        #
        # This is a workaround for escape sequences not tracking
        # the buffer position (accounting for scrolling).
        #
        # See also: https://unix.stackexchange.com/a/278888

        printf "\n\n\n"
        tput cuu 3

        tput sc

    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Display spinner while the commands are being executed.

    while kill -0 "$PID" &>/dev/null; do

        frame_text="   [${FRAMES:i++%NUMBER_OR_FRAMES:1}] $MSG"

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Print frame text.

        if [ "$GITHUB_ACTIONS" != "true" ]; then
            printf "%s\n" "$frame_text"
        else
            printf "%s" "$frame_text"
        fi

        sleep 0.2

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        # Clear frame text.

        if [ "$GITHUB_ACTIONS" != "true" ]; then
            tput rc
        else
            printf "\r"
        fi

    done
}
