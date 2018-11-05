install_brew () {
    e_newline
    e_header "Installing homebrew..."
    xcode-select --install
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    e_newline && e_done "Install homebrew"
}

install_tmux () {
    e_newline
    e_header "Installing tmux..."
    brew install tmux
    e_newline && e_done "Install tmux"
}

install_pyenv_requirements() {
    e_newline
    e_header "Installing pyenv requirements..."
    brew install openssl readline sqlite3 xz zlib
    e_newline && e_done "Install pyenv requirements..."
}
