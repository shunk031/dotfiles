#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/common/kotlin.sh"

function setup() {
    source "${SCRIPT_PATH}"
}

function teardown() {
    run uninstall_java
    run uninstall_kotlin
    run uninstall_gradle
    run uninstall_android_studio
}

@test "[macos] kotlin" {
    DOTFILES_DEBUG=1 bash "${SCRIPT_PATH}"

    [ -x "$(command -v java)" ]
    [ -x "$(command -v kotlin)" ]
    [ -x "$(command -v gradle)" ]

    run brew info android-studio
    [ "${status}" -eq 0 ]
}
