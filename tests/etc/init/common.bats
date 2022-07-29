#!/usr/bin/env bats

function setup() {
    export DOTPATH="."
}

# @test "test for fzf" {
#     load "$DOTPATH"/etc/init/common/01_fzf.sh
#     install_fzf

#     command -v fzf
# }

@test "test for tpm (tmux-plugin-manager)" {
    . "$DOTPATH"/etc/init/common/tpm.sh
}
