#!/usr/bin/env bats

readonly CMUX_PAYLOAD_PATH="./home/dot_cmux/private_cmux.json"
readonly CMUX_SYMLINK_TEMPLATE="./home/dot_config/cmux/symlink_cmux.json.tmpl"
readonly LEGACY_CMUX_PAYLOAD_PATH="./home/dot_config/cmux/private_cmux.json"
readonly LEGACY_CMUX_SYMLINK_TEMPLATE="./home/dot_config/cmux/symlink_private_cmux.json.tmpl"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly UBUNTU_CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/ubuntu/common"

@test "[common] cmux config payload lives under dot_cmux and is exposed via a config symlink template" {
    [ -f "${CMUX_PAYLOAD_PATH}" ]
    [ -f "${CMUX_SYMLINK_TEMPLATE}" ]
    [ ! -e "${LEGACY_CMUX_PAYLOAD_PATH}" ]
    [ ! -e "${LEGACY_CMUX_SYMLINK_TEMPLATE}" ]
    [ "$(< "${CMUX_SYMLINK_TEMPLATE}")" = "{{ .chezmoi.sourceDir }}/dot_cmux/private_cmux.json" ]

    run grep -F 'cmux creates this template on launch when ~/.config/cmux/cmux.json is missing.' "${CMUX_PAYLOAD_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] cmux canonical payload does not apply a second ~/.cmux target" {
    run grep -Fx ".cmux" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] cmux target is ignored on Ubuntu" {
    run grep -Fx ".config/cmux" "${UBUNTU_CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}
