# zshrc

source ~/dotfiles/zsh/functions.zsh
source ~/dotfiles/zsh/path.zsh
source ~/dotfiles/zsh/alias.zsh
source ~/dotfiles/zsh/pyenv.zsh

# export TERM color as 256 colors
export TERM=xterm-256color

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# load password as environment variable
if [ -e $HOME/dotfiles/my_passwd ]; then
    source $HOME/dotfiles/my_passwd
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/cyberangel/.sdkman"
[[ -s "/home/cyberangel/.sdkman/bin/sdkman-init.sh" ]] && source "/home/cyberangel/.sdkman/bin/sdkman-init.sh"


# auto-start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && tmux


# Run one instance of devilspie to manage window sizes (Linux only)
if [[ "$OSTYPE" =~ "linux-gnu" ]]; then
  if [ ! `pidof devilspie` ]; then
    (devilspie &)
  fi
fi

# added by travis gem
[ -f /home/cyberangel/.travis/travis.sh ] && source /home/cyberangel/.travis/travis.sh
