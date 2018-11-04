# zshrc

source ${HOME}/.dotfiles/setup.sh

# source ~/dotfiles/zsh/functions.zsh
# source ${HOME}dotfiles/bin.zsh/paths.zsh
# source ${HOME}/dotfiles/bin.zsh/alias.zsh
# source ${HOME}/dotfiles/bin.zsh/pyenv.zsh
# source ${HOME}/dotfiles/bin.zsh/goenv.zsh
# source ${HOME}/dotfiles/bin.zsh/rbenv.zsh

# export TERM color as 256 colors
export TERM=xterm-256color


# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# load password as environment variable
if [ ! -f ${HOME}/.dotfiles/.secret.zsh ]; then
    cp ${HOME}/.dotfiles/.secret.zsh.example ${HOME}/.dotfiles/.secret.zsh
fi
source ${HOME}/.dotfiles/.secret.zsh

# auto-start tmux
if has 'tmux'; then
    :
else
    source ${HOME}/.dotfiles/etc/linux/install.sh
    install_tmux
fi

[[ -z "$TMUX" && ! -z "$PS1" ]] && tmux

# Run one instance of devilspie to manage window sizes (Linux only)
if is_linux; then
    if has 'devilspie'; then
        :
    else
        source ${HOME}/.dotfiles/etc/linux/install.sh
        install_devilspie
    fi
    # (devilspie &)
fi
