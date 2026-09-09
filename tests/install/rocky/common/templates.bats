#!/usr/bin/env bats

readonly SCRIPT_TEMPLATE_DIR="./home/.chezmoiscripts/ubuntu"
readonly EXTERNAL_TEMPLATE="./home/.chezmoiexternal.yaml.tmpl"
readonly TMUX_TEMPLATE="./home/dot_tmux.conf.tmpl"

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

@test "[rocky-server] tmux template accepts Rocky Linux" {
    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${TMUX_TEMPLATE}"
    [ "${status}" -eq 0 ]
    run grep -F 'include "dot_tmux.conf.d/os/ubuntu_server.conf"' "${TMUX_TEMPLATE}"
    [ "${status}" -eq 0 ]
}

@test "[rocky-server] SSH environment template configures the Rocky server" {
    local template="./home/.chezmoiscripts/rocky/run_once_50-server-configure-ssh-env.sh.tmpl"

    run grep -F 'eq .chezmoi.osRelease.id "rocky"' "${template}"
    [ "${status}" -eq 0 ]
    run grep -F '../install/rocky/server/ssh_server.sh' "${template}"
    [ "${status}" -eq 0 ]
}

@test "[rocky-common] GPG agent template selects the Rocky terminal pinentry" {
    local template="./home/private_dot_gnupg/gpg-agent.conf.tmpl"

    run grep -F 'else if eq .chezmoi.osRelease.id "rocky"' "${template}"
    [ "${status}" -eq 0 ]
    run grep -F 'pinentry-program /usr/bin/pinentry-curses' "${template}"
    [ "${status}" -eq 0 ]
}
