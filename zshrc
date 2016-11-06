#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/cyberangel/.sdkman"
[[ -s "/home/cyberangel/.sdkman/bin/sdkman-init.sh" ]] && source "/home/cyberangel/.sdkman/bin/sdkman-init.sh"

# added by travis gem
[ -f /home/cyberangel/.travis/travis.sh ] && source /home/cyberangel/.travis/travis.sh

# auto-start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && tmux

# add alias
alias geeknote="python ~/geeknote/geeknote/geeknote.py"
alias browser-sync-start="browser-sync start --server --files \"**/*\""
alias xm="load_xmod_map "

# add some emacs aliases
alias ekill="emacsclient -e '(kill-emacs)'"
alias e='emacsclient -n'

# add pyenv and conda(python) aliases
alias activate="source $PYENV_ROOT/versions/miniconda3-latest/bin/activate"
alias deactivate="source $PYENV_ROOT/versions/miniconda3-latest/bin/deactivate"

# add jupyter notebook ailias
export JUPYTER_URL_PATH="http://localhost:8888/"
alias jd='PWDPATH=`pwd`;open $JUPYTER_URL_PATH"tree${PWDPATH/#$HOME}"'
alias jn='jupyter notebook'

# h-auth script ailias
alias hauth="auth.py"

# arduino ailias
PATH="$PATH":/opt/ardiono-1.6.11
alias arduino="/opt/arduino-1.6.11/arduino"

# ailias up directory
alias up="cd ../"

# export android sdk path
export PATH=${PATH}:~/Android/Sdk/tools:~/Android/Sdk/platform-tools

# add genymotion path
PATH="$PATH":~/android-dev/genymotion

# add emacs-python path
PATH="$PATH":~/.local/bin

# add composer path
PATH="$PATH":~/.composer/vender/bin

# add my script path
PATH="$PATH":~/dotfiles/script
PATH="$PATH":~/emacs.d/etc



# Setup pyenv environment
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"



# Setup pyenv-virtualenv enviroment
eval "$(pyenv virtualenv-init -)"



# disable virtualenv prompt 
export PYENV_VIRTUALENV_DISABLE_PROMPT=1



# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi



# Run one instance of devilspie to manage window sizes (Linux only)
if [[ "$OSTYPE" =~ "linux-gnu" ]]; then
  if [ ! `pidof devilspie` ]; then
    (devilspie &)
  fi
fi



# Change Keybindings
# if [ -s ~/.Xmodmap ]; then
#     xmodmap ~/.Xmodmap
# fi

# Setting for Emacs-shell
[[ $EMACS = t ]] && unsetopt zle



# load xmodmap function
load_xmod_map(){
    xmodmap ~/.Xmodmap
    echo "Now loaded Xmod map"
}

python6() {
    echo -e "run script in python 2 env."
    pyenv global search-tec2
    python $1

    echo -e "run script in python 3 env."
    pyenv global search-tec3
    python $1
}

# added by travis gem
[ -f /home/cyberangel/.travis/travis.sh ] && source /home/cyberangel/.travis/travis.sh
