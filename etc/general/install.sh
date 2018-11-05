install_prezto () {
    e_newline
    e_header "Installing prezto..."

    git clone -q --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ln -sfnv ${DOTPATH}/.zsh/prezto/prompt_my_powerline_setup.zsh ${HOME}/.zprezto/modules/prompt/functions/prompt_my_powerline_setup
}
