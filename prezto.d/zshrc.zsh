# zshrc

# source ~/dotfiles/zsh/functions.zsh
source ~/dotfiles/bin.zsh/paths.zsh
# source ~/dotfiles/zsh/alias.zsh
source ~/dotfiles/bin.zsh/pyenv.zsh
source ~/dotfiles/bin.zsh/goenv.zsh
source ~/dotfiles/bin.zsh/rbenv.zsh

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


# auto-start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && tmux



# Run one instance of devilspie to manage window sizes (Linux only)
if [[ "$OSTYPE" =~ "linux-gnu" ]]; then
  if [ ! `pidof devilspie` ]; then
    (devilspie &)
  fi
fi
