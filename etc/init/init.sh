#!/bin/bash

source ${DOTPATH}/setup.sh
source ${DOTPATH}/etc/general/install.sh

#
# powerline fonts
#

if [ ! -e "${DOTPATH}/.github/powerline_font" ]; then
    install_powerline_font
fi

#
# prezto
#

if [ ! -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]; then
    install_prezto
fi

#
# Load OS specific install.sh
#

if is_linux; then
    source ${DOTPATH}/etc/linux/install.sh

elif is_osx; then
    source ${DOTPATH}/etc/mac/install.sh
    install_brew

else
    log_fail "$(ostype) not supported."
fi

#
# tmux
#

if ! has 'tmux'; then
    install_tmux
fi

#
# pyenv
#

if ! has 'pyenv'; then
    install_pyenv_requirements
    install_pyenv
    install_pyenv_virtualenv
fi

#
# OS specific applications
#

if is_linux; then
    if ! has 'devilspie'; then
        install_devilspie
    fi

elif is_osx; then
    :
fi
