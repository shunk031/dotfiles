#!/usr/bin/env bats

readonly GHOSTTY_PAYLOAD_PATH="./home/dot_ghostty/config"
readonly GHOSTTY_SYMLINK_TEMPLATE="./home/dot_config/ghostty/symlink_config.tmpl"
readonly LEGACY_GHOSTTY_PAYLOAD_PATH="./home/dot_config/ghostty/config"
readonly LEGACY_GHOSTTY_ALT_SYMLINK_TEMPLATE="./home/dot_config/ghostty/symlink_config.ghostty.tmpl"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly UBUNTU_CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/ubuntu/common"

@test "[common] ghostty config payload lives under dot_ghostty and is exposed via a config symlink template" {
    [ -f "${GHOSTTY_PAYLOAD_PATH}" ]
    [ -f "${GHOSTTY_SYMLINK_TEMPLATE}" ]
    [ ! -e "${LEGACY_GHOSTTY_PAYLOAD_PATH}" ]
    [ ! -e "${LEGACY_GHOSTTY_ALT_SYMLINK_TEMPLATE}" ]
    [ "$(< "${GHOSTTY_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_ghostty/config" ]

    run grep -F 'window-theme = "ghostty"' "${GHOSTTY_PAYLOAD_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] ghostty canonical payload does not apply a second ~/.ghostty target" {
    run grep -Fx ".ghostty" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] ghostty target is ignored on Ubuntu" {
    run grep -Fx ".config/ghostty" "${UBUNTU_CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}
