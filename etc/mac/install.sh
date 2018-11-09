install_brew () {
    e_newline
    e_header "Installing homebrew..."
    xcode-select --install
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    e_newline && e_done "Install homebrew"
}

install_mac_tools() {
    e_newline
    e_header "Installing Mac tools..."
    brew install gcc
    brew install fontforge
    brew install aspell --lang=en
}

install_tmux () {
    e_newline
    e_header "Installing tmux..."
    brew install tmux
    brew install reattach-to-user-namespace
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

install_emacs() {
    if ! brew list | grep -q emacs-plus; then
        EMACS_APP_DIR=/usr/local/Cellar/emacs-plus/26.1/Emacs.app/

        e_newline
        e_header "Installing emacs..."
        brew tap d12frosted/emacs-plus
        brew install emacs-plus

        e_header "Creating symbolic link..."
        ln -s  $EMACS_APP_DIR /Applications/
        if [ ? -gt 0 ]; then
            log_fail "Can't create symbolic link to Applications"
            exit 1
        fi
        e_newline && e_done "Install emacs..."
    fi
}

install_spacemacs_requirements() {
    e_newline
    e_header "Installing Spacemacs requirements..."

    if ! fc-list | grep -q "Source Code Pro"; then
        e_header "Installing font-source-code-pro..."
        brew tap caskroom/fonts && brew cask install font-source-code-pro
        e_newline && e_done "Install font-source-code-pro..."
    fi
    e_newline && e_done "Install Spacemacs requirements..."
}
