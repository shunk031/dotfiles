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

install_tmux_mem_cpu_load_requirements() {
    e_newline
    e_header "Installing tmux-mem-cpu-load requirements"
    brew install cmake
    e_newline && e_done "Install tmux-cpu-load requirements"
}

install_pyenv_requirements() {
    e_newline
    e_header "Installing pyenv requirements..."
    brew install openssl readline sqlite3 xz zlib
    e_newline && e_done "Install pyenv requirements..."
}

install_rbenv_requirements() {
    e_newline
    e_header "Installing rbenv requirements..."
    brew install openssl libyaml libffi
    e_newline && e_done "Install rbenv requirements..."
}
