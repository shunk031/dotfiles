#!/usr/bin/env bats

readonly SCRIPT_TEMPLATE_DIR="./home/.chezmoiscripts/ubuntu"
readonly EXTERNAL_TEMPLATE="./home/.chezmoiexternal.yaml.tmpl"

@test "[rocky-common] required Linux templates route Rocky Linux to Rocky scripts" {
    local template

    for template in \
        run_once_00-setup-ssh.sh.tmpl \
        run_once_08-install-tmux.sh.tmpl \
        run_once_before_40-setup-timezone.sh.tmpl \
        run_once_before_50-common-dependencies.sh.tmpl; do
        run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
        run grep -F '../install/rocky/' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
    done
}

@test "[rocky-server] server templates route Rocky Linux to Rocky scripts" {
    local template

    for template in \
        run_once_50-server-install-mics.sh.tmpl \
        run_once_50-server-setup-locale.sh.tmpl; do
        run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
        run grep -F '../install/rocky/server/' "${SCRIPT_TEMPLATE_DIR}/${template}"
        [ "${status}" -eq 0 ]
    done
}

@test "[rocky-server] Starship installer uses the portable system shell" {
    run grep -F 'curl -sS "${url}" | sh -s --' ./install/ubuntu/server/starship.sh
    [ "${status}" -eq 0 ]
}

@test "[rocky-common] external template accepts Rocky Linux" {
    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${EXTERNAL_TEMPLATE}"
    [ "${status}" -eq 0 ]
}
