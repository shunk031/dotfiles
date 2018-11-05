install_tmux() {
    e_newline
    e_header "Installing tmux..."
    sudo apt-get -qq install -y tmux > /dev/null
    e_newline && e_done "Install tmux"
}

install_tmux_mem_cpu_load_requirements() {
    e_newline
    e_header "Installing tmux-mem-cpu-load requirements..."
    sudo apt-get -qq install -y cmake > /dev/null
    e_newline && e_done "Install tmux-mem-cpu-load requirements"
}

install_devilspie() {
    e_newline
    e_header "Installing devilspie..."
    sudo apt-get -qq install -y devilspie > /dev/null

    e_newline && e_done "Install devilspie"
}

install_pyenv_requirements() {
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
    e_newline && e_done "Install pyenv requirements..."
}

install_rbenv_requirements() {
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
    e_newline && e_done "Install rbenv requirements..."
}
