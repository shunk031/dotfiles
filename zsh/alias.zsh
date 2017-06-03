# Aliases

# for up directory
alias up="cd ../"

# for load_xmod_map function
alias xm="load_xmod_map "

# for browser-sync start server
alias browser-sync-start="browser-sync start --server --files \"**/*\""

# for some emacs aliases
alias ekill="emacsclient -e '(kill-emacs)'"
alias e='emacsclient -n'

# for pyenv and conda(python) aliases
alias activate="source $PYENV_ROOT/versions/miniconda3-latest/bin/activate"
alias deactivate="source $PYENV_ROOT/versions/miniconda3-latest/bin/deactivate"

# for h-auth script ailias
alias hauth="auth.py"

# for change keyboard layout
alias chkey="fcitx-imlist -t"

# for starting jupyter notebook
alias jn='jupyter notebook'

# for finding directory of neologd dictionary
alias which-neologd='echo `mecab-config --dicdir`"/mecab-ipadic-neologd"'

# for setting MTU value to 1000
if [ -e /sys/class/net/enp2s0 ]; then
    alias ssh-mtu="sudo ifconfig enp2s0 mtu 1000"
elif [ -e /sys/class/net/wlp2s0 ]; then
    alias ssh-mtu="sudo ifconfig wlp2s0 mtu 1000"
fi
