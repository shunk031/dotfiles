POWERLINE_FONT_DIR=${DOTPATH}/.github/powerline_fonts

install_powerline_font() {
    e_newline
    e_header "Installing powerline font..."

    git clone -q https://github.com/powerline/fonts.git $POWERLINE_FONT_DIR --depth=1
    ${POWERLINE_FONT_DIR}/install.sh

    e_newline && e_done "Install powerline"
}

install_prezto() {
    e_newline
    e_header "Installing prezto..."

    git clone -q --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ln -sfnv ${DOTPATH}/.zsh/prezto/prompt/prompt_my_powerline_setup.zsh ${HOME}/.zprezto/modules/prompt/functions/prompt_my_powerline_setup

    e_newline && e_done "Install prezto"
}

install_tpm() {
    TPM_DIR=~/.tmux/plugins/tpm

    e_header "Installing tpm (tmux plugin manager)..."
    git clone -q https://github.com/tmux-plugins/tpm $TPM_DIR
    e_newline && e_done "Install tpm"
}

install_tmux_mem_cpu_load() {
    git clone -q https://github.com/thewtex/tmux-mem-cpu-load.git ${DOTPATH}/.github/tmux-mem-cpu-load
    current_dir=`pwd`
    cd ${DOTPATH}/.github/tmux-mem-cpu-load
    cmake .
    make
    sudo make install
    cd current_dir
}

install_pyenv() {
    PYENV_DIR=${HOME}/.pyenv
    PYENV_VIRTUALENV_DIR=${PYENV_DIR}/plugins/pyenv-virtualenv

    e_header "Installing pyenv..."
    git clone -q https://github.com/yyuu/pyenv.git $PYENV_DIR
    e_newline && e_done "Install pyenv"

    e_header "Installing pyenv-virtualenv..."
    git clone -q https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
    e_newline && e_done "Install pyenv-virtualenv"
}

install_rbenv() {
    RBENV_DIR=${HOME}/.rbenv

    e_header "Installing rbenv..."
    git clone -q https://github.com/rbenv/rbenv.git $RBENV_DIR
    ${RBENV_DIR}/src/configure && make -C src
    e_newline && e_done "Install rbenv"

    e_header "Installing ruby-build..."
    mkdir -p ${RBENV_DIR}/plugins
    git clone -q https://github.com/rbenv/ruby-build.git ${RBENV_DIR}/plugins/ruby-build
    e_newline && e_done "Install ruby-build"
}
