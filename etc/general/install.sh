install_powerline_font () {
    POWERLINE_FONT_DIR=${DOTPATH}/.github/powerline_fonts

    e_newline
    e_header "Installing powerline font..."
    e_arrow "Clone repository"
    git clone -q https://github.com/powerline/fonts.git $POWERLINE_FONT_DIR --depth=1
    e_arrow "Run install.sh"
    ${POWERLINE_FONT_DIR}/install.sh

    e_newline && e_done "Install powerline"
}

install_fzf () {
    e_newline
    e_header "Installing fzf..."
    e_arrow "Clone repository"
    git clone -q --depth 1 https://github.com/junegunn/fzf.git ~/.fzf > /dev/null
    ~/.fzf/install --key-bindings --completion --no-update-rc

    e_newline && e_done "install fzf"
}

install_prezto () {
    e_newline
    e_header "Installing prezto..."
    e_arrow "Clone repository"
    git clone -q --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" > /dev/null
    e_arrow "Symlink powerline theme"
    ln -sfnv ${DOTPATH}/.zsh/prezto/prompt/prompt_my_powerline_setup.zsh ${HOME}/.zprezto/modules/prompt/functions/prompt_my_powerline_setup

    e_newline && e_done "Install prezto"
}

install_prezto_fzf () {
    PREZTO_FZF_DIR="${ZDOTDIR:-$HOME}"/.zprezto/contrib/fzf

    e_newline
    e_header "Installing prezto-fzf..."
    mkdir -p $PREZTO_FZF_DIR
    git clone -q --recursive https://github.com/gpanders/fzf-prezto.git $PREZTO_FZF_DIR > /dev/null
    $PREZTO_FZF_DIR/external/install --bin
    e_newline && e_done "install prezto-fzf"
}

install_tpm () {
    TPM_DIR=~/.tmux/plugins/tpm

    e_newline
    e_header "Installing tpm (tmux plugin manager)..."
    e_arrow "Clone repository"
    git clone -q https://github.com/tmux-plugins/tpm $TPM_DIR
    e_newline && e_done "Install tpm"
}

install_tmux_mem_cpu_load () {
    TMUX_MEM_CPU_LOAD_DIR=${DOTPATH}/.github/tmux-mem-cpu-load

    e_newline
    e_header "Installing tmux-mem-cpu-load..."
    e_arrow "Clone repository"
    git clone -q https://github.com/thewtex/tmux-mem-cpu-load.git ${TMUX_MEM_CPU_LOAD_DIR}

    e_arrow "Make and install"
    current_dir=`pwd`
    cd ${TMUX_MEM_CPU_LOAD_DIR}
    cmake .
    make
    sudo make install
    cd $current_dir
    e_newline && e_done "Install tmux-mem-cpu-load"
}

install_tpm_plugins () {
    e_newline
    e_header "Installing tmux plugins using tpm..."
    e_arrow "Run install_plugins.sh"
    bash ${HOME}/.tmux/plugins/tpm/scripts/install_plugins.sh
    e_newline && e_done "Install tmux plugins"
}

install_pyenv () {
    PYENV_DIR=${HOME}/.pyenv
    PYENV_VIRTUALENV_DIR=${PYENV_DIR}/plugins/pyenv-virtualenv

    e_newline
    e_header "Installing pyenv..."
    e_arrow "Clone repository"
    git clone -q https://github.com/yyuu/pyenv.git $PYENV_DIR
    e_newline && e_done "Install pyenv"

    e_newline
    e_header "Installing pyenv-virtualenv..."
    e_arrow "Clone repository"
    git clone -q https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
    e_newline && e_done "Install pyenv-virtualenv"
}

install_rbenv () {
    RBENV_DIR=${HOME}/.rbenv

    e_newline
    e_header "Installing rbenv..."
    e_arrow "Clone repository"
    git clone -q https://github.com/rbenv/rbenv.git $RBENV_DIR

    e_arrow "Make and install"
    current_dir=`pwd`
    cd ${RBENV_DIR} && src/configure && make -C src
    cd $current_dir
    e_newline && e_done "Install rbenv"

    e_newline
    e_header "Installing ruby-build..."
    mkdir -p ${RBENV_DIR}/plugins
    git clone -q https://github.com/rbenv/ruby-build.git ${RBENV_DIR}/plugins/ruby-build
    e_newline && e_done "Install ruby-build"
}

install_goenv () {
    e_newline
    e_header "Installing goenv..."
    e_arrow "Clone repository"
    git clone -q https://github.com/syndbg/goenv.git ~/.goenv
    e_newline && e_done "Install goenv"
}

install_spacemacs () {
    e_newline
    e_header "Installing spacemacs..."
    e_arrow "Clone repository"
    git clone -q https://github.com/syl20bnr/spacemacs ~/.emacs.d
    e_newline && e_done "Install spacemacs"
}

setup_git () {
    if [ ! -e "${HOME}/.config/git" ]; then
        GIT_CONFIG_DIR=${HOME}/.config/git
        e_newline
        e_header "Create symlink of gitignore_global to $GIT_CONFIG_DIR"

        mkdir -p $GIT_CONFIG_DIR
        ln -sfnv ${DOTPATH}/.gitignore_global $GIT_CONFIG_DIR/ignore

        e_newline && e_done "Setup git"
    fi
}
