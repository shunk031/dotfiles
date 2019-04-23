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
    install_linux_tools

elif is_osx; then
    source ${DOTPATH}/etc/mac/install.sh
    if ! has 'brew'; then
        install_brew
    fi

    if ! has 'gcc' || ! has 'fontforge' || ! has 'aspell'; then
        install_mac_tools
    fi

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
    install_tpm_plugins
fi

#
# pyenv
#

if [ ! -e "${HOME}/.pyenv" ]; then
    install_pyenv_requirements
    install_pyenv
fi

#
# rbenv
#

if [ ! -e "${HOME}/.rbenv" ]; then
    install_rbenv_requirements
    install_rbenv
fi

#
# goenv
#

if [ ! -e "${HOME}/.goenv" ]; then
    install_goenv
fi

#
# emacs
#

install_emacs

if ! has 'emacs' || ! brew list | grep -q emacs-plus ; then
    install_emacs
fi

#
# spacemacs
#

if [ ! -e "${HOME}/.emacs.d" ]; then
    install_spacemacs_requirements
    install_spacemacs
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

#
# setup git config
#

if has 'git'; then
   setup_git
fi

e_newline && e_done "All init process is done."
