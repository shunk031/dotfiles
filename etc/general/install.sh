POWERLINE_FONT_DIR=${DOTPATH}/.github/powerline_fonts

install_powerline_font() {
    e_newline
    e_header "Installing powerline font..."

    git clone -q https://github.com/powerline/fonts.git $POWERLINE_FONT_DIR --depth=1
    ${POWERLINE_FONT_DIR}/install.sh

    e_newline && e_done "Install powerline"
}

install_prezto () {
    e_newline
    e_header "Installing prezto..."

    git clone -q --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ln -sfnv ${DOTPATH}/.zsh/prezto/prompt_my_powerline_setup.zsh ${HOME}/.zprezto/modules/prompt/functions/prompt_my_powerline_setup

    e_newline && e_done "Install prezto"
}
