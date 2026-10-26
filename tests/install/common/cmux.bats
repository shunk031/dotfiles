#!/usr/bin/env bats

readonly CMUX_PAYLOAD_PATH="./home/dot_cmux/private_cmux.json"
readonly CMUX_TEMPLATE="./home/private_dot_config/cmux/private_cmux.json.tmpl"
readonly LEGACY_CMUX_PAYLOAD_PATH="./home/private_dot_config/cmux/private_cmux.json"
readonly LEGACY_CMUX_SYMLINK_TEMPLATE="./home/private_dot_config/cmux/symlink_private_cmux.json.tmpl"
readonly CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/common"
readonly LINUX_CHEZMOIIGNORE_PATH="./home/.chezmoitemplates/chezmoiignore.d/linux/common"

@test "[common] cmux config payload is rendered from its private source" {
    [ -f "${CMUX_PAYLOAD_PATH}" ]
    [ -f "${CMUX_TEMPLATE}" ]
    [ ! -e "${LEGACY_CMUX_PAYLOAD_PATH}" ]
    [ ! -e "${LEGACY_CMUX_SYMLINK_TEMPLATE}" ]
    [ "$(< "${CMUX_TEMPLATE}")" = '{{- include "dot_cmux/private_cmux.json" -}}' ]

    run grep -F 'cmux creates this template on launch when ~/.config/cmux/cmux.json is missing.' "${CMUX_PAYLOAD_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] cmux canonical payload does not apply a second ~/.cmux target" {
    run grep -Fx ".cmux" "${CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}

@test "[common] cmux target is ignored on Linux" {
    run grep -Fx ".config/cmux" "${LINUX_CHEZMOIIGNORE_PATH}"
    [ "${status}" -eq 0 ]
}
