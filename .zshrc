# zshrc

source ${HOME}/.dotfiles/setup.sh
source ${DOTPATH}/.zsh/20_pyenv.sh
source ${DOTPATH}/.zsh/20_rbenv.sh

# source ~/dotfiles/zsh/functions.zsh
# source ${HOME}dotfiles/bin.zsh/paths.zsh
# source ${HOME}/dotfiles/bin.zsh/alias.zsh
# source ${HOME}/dotfiles/bin.zsh/pyenv.zsh
# source ${HOME}/dotfiles/bin.zsh/goenv.zsh
# source ${HOME}/dotfiles/bin.zsh/rbenv.zsh

# export TERM color as 256 colors
export TERM=xterm-256color

#
# powerline font
#

if [ ! -e "${DOTPATH}/.github/powerline_font" ]; then
    source ${DOTPATH}/etc/general/install.sh
    install_powerline_font
fi

#
# prezto
#

if [ ! -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]; then
    source ${DOTPATH}/etc/general/install.sh
    install_prezto
fi
source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

#
# Secret File
#

# load password as environment variable
if [ ! -f ${DOTPATH}/.secret.zsh ]; then
    cp ${DOTPATH}/.secret.zsh.example ${DOTPATH}/.secret.zsh
fi
source ${DOTPATH}/.secret.zsh

#
# tmux
#

if ! has 'tmux'; then
    if is_linux; then
        source ${DOTPATH}/etc/linux/install.sh
    elif is_osx; then
        source ${DOTPATH}/etc/mac/install.sh
    fi

    install_tmux
fi
# [[ -z "$TMUX" && ! -z "$PS1" ]] && tmux

#
# devilspie
#

# Run one instance of devilspie to manage window sizes (Linux only)
if is_linux; then
    if ! has 'devilspie'; then
        source ${DOTPATH}/etc/linux/install.sh
        install_devilspie
    fi
    # (devilspie &)
fi
