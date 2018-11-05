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
    ln -sfnv ${DOTPATH}/.zsh/prezto/prompt_my_powerline_setup.zsh ${HOME}/.zprezto/modules/prompt/functions/prompt_my_powerline_setup

    e_newline && e_done "Install prezto"
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
    ${HOME}/.rbenv/src/configure && make -C src
    e_newline && e_done "Install rbenv"

    e_header "Installing ruby-build..."
    mkdir -p "$(rbenv root)"/plugins
    git clone -q https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
    e_newline && e_done "Install ruby-build"
}
