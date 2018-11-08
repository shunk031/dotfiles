# zshrc

source ${HOME}/.dotfiles/setup.sh
source ${DOTPATH}/.zsh/path.sh
source ${DOTPATH}/.zsh/pyenv.sh
source ${DOTPATH}/.zsh/rbenv.sh
source ${DOTPATH}/.zsh/goenv.sh

# source ~/dotfiles/zsh/functions.zsh
# source ${HOME}dotfiles/bin.zsh/paths.zsh
# source ${HOME}/dotfiles/bin.zsh/alias.zsh
# source ${HOME}/dotfiles/bin.zsh/pyenv.zsh
# source ${HOME}/dotfiles/bin.zsh/goenv.zsh
# source ${HOME}/dotfiles/bin.zsh/rbenv.zsh

# export TERM color as 256 colors
export TERM=xterm-256color

#
# prezto
#

source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

#
# Secret File
#

# load password as environment variable
if [ ! -f ${DOTPATH}/.secret.zsh ]; then
    cp ${DOTPATH}/.secret.zsh.example ${DOTPATH}/.secret.zsh
fi
source ${DOTPATH}/.secret.zsh

# [[ -z "$TMUX" && ! -z "$PS1" ]] && tmux

#
# devilspie
#

# Run one instance of devilspie to manage window sizes (Linux only)
if is_linux; then
    # (devilspie &)
    :
fi

if (which zprof > /dev/null) ;then
    zprof | less
fi
