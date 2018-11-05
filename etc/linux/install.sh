install_devilspie() {
    e_newline
    e_header "Installing devilspie"
    sudo apt-get install -y -qq devilspie

    e_newline && e_done "Install devilspie"
}

install_tmux() {
    e_newline
    e_header "Installing tmux"
    sudo apt-get install -y -qq tmux

    e_newline && e_done "Install tmux"
}
