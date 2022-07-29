#!/usr/bin/env bats

load etc/deploy.sh

function setup() {
    export DOTPATH="./dotfiles"
}

@test "test for deploying dotfiles for GUI" {
    deploy_dotfiles_cmd "gui"
}
