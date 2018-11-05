install_tmux() {
    e_newline
    e_header "Installing tmux..."
    sudo apt-get install -y -qq tmux
    e_newline && e_done "Install tmux"
}

install_devilspie() {
    e_newline
    e_header "Installing devilspie..."
    sudo apt-get install -y -qq devilspie

    e_newline && e_done "Install devilspie"
}

install_pyenv_requirements() {
    e_newline
    e_header "Installing pyenv requirements..."
    sudo apt-get install -y -qq \
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
         libffi-dev
    e_newline && e_done "Install pyenv requirements..."
}
