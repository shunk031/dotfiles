#!/usr/bin/env bats

@test "[macos] misc includes cmux tap" {
    run bash -lc 'source ./install/macos/common/misc.sh; [ "${#BREW_TAPS[@]}" -eq 1 ] && [ "${BREW_TAPS[0]}" = "manaflow-ai/cmux" ]'
    [ "${status}" -eq 0 ]
}

@test "[macos] misc defines tap helpers" {
    run bash -lc 'source ./install/macos/common/misc.sh; [ "$(type -t is_brew_tap_installed)" = "function" ] && [ "$(type -t install_brew_taps)" = "function" ]'
    [ "${status}" -eq 0 ]
}

@test "[macos] install_brew_taps skips in ci" {
    run bash -lc 'source ./install/macos/common/misc.sh; CI=true install_brew_taps'
    [ "${status}" -eq 0 ]
}
