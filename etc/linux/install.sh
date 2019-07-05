install_linux_tools () {
    sudo apt-get -qq install -y \
         autossh \
         golang > /dev/null
}

install_zsh () {
    e_newline
    e_header "Installing zsh..."
    sudo apt-get install -qq install -y zsh /dev/null
    e_newline && e_done "Install zsh"
}

install_tmux () {
    e_newline
    e_header "Installing tmux..."
    sudo apt-get -qq install -y tmux > /dev/null
    e_newline && e_done "Install tmux"
}

install_tmux_mem_cpu_load_requirements () {
    e_newline
    e_header "Installing tmux-mem-cpu-load requirements..."
    sudo apt-get -qq install -y \
         build-essential \
         gcc \
         cmake > /dev/null
    e_newline && e_done "Install tmux-mem-cpu-load requirements"
}

install_devilspie () {
    e_newline
    e_header "Installing devilspie..."
    sudo apt-get -qq install -y devilspie > /dev/null
    e_arrow "Symlink devilspie-script.ds"
    ln -sfnv ${DOTPATH}/etc/linux/devilspie-script.ds ${HOME}/.devilspie
    e_newline && e_done "Install devilspie"
}

install_pyenv_requirements () {
    e_newline
    e_header "Installing pyenv requirements..."
    sudo apt-get -qq install -y \
         make \
         build-essential \
         libssl-dev \
         zlib1g-dev \
         libbz2-dev \
         libreadline-dev \
         libsqlite3-dev \
         wget \
         curl \
         llvm \
         libncurses5-dev \
         xz-utils \
         tk-dev \
         libxml2-dev \
         libxmlsec1-dev \
         libffi-dev > /dev/null
    e_newline && e_done "Install pyenv requirements"
}

install_rbenv_requirements () {
    e_newline
    e_header "Installing rbenv requirements..."
    sudo apt-get -qq install -y \
         autoconf \
         bison \
         build-essential \
         libssl-dev \
         libyaml-dev \
         libreadline6-dev \
         zlib1g-dev \
         libncurses5-dev \
         libffi-dev \
         libgdbm5 \
         libgdbm-dev > /dev/null
    e_newline && e_done "Install rbenv requirements"
}

install_emacs() {
    if ! has 'emacs'; then
        e_newline
        e_header "Installing emacs25 requirements..."
        sudo apt-get -qq install software-properties-common > /dev/null
        e_arrow "Add repository"
        sudo add-apt-repository -y ppa:kelleyk/emacs
        e_arrow "Update apt"
        sudo apt-get -qq update > /dev/null
        e_arrow "Install emacs25"
        sudo apt-get -qq install emacs25 > /dev/null
        e_newline && e_done "Install emacs25"
    fi
}

install_spacemacs_requirements () {
    FONT_DIR=~/.fonts/adobe-fonts/source-code-pro

    e_newline
    e_header "Installing source code pro font..."
    e_arrow "Clone repository"
    git clone -q --depth 1 --branch release https://github.com/adobe-fonts/source-code-pro.git $FONT_DIR

    e_arrow "Copying fonts..."
    fc-cache -f $FONT_DIR
}

install_ghq () {
    go get github.com/motemen/ghq
}
