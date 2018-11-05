#!/bin/bash

source ${DOTPATH}/setup.sh
source ${DOTPATH}/etc/general/install.sh

#
# powerline fonts
#

if [ ! -e "${DOTPATH}/.github/powerline_fonts" ]; then
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
    install_tpm
    install_tmux_mem_cpu_load_requirements
    install_tmux_mem_cpu_load
fi

#
# pyenv
#

if [ ! -e "${HOME}/.pyenv"]; then
    install_pyenv_requirements
    install_pyenv
fi

#
# rbenv
#

if [ ! -e "${HOME}/.rbenv"]; then
    install_rbenv_requirements
    install_rbenv
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
