#!/bin/bash
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/cyberangel/.sdkman"
[[ -s "/home/cyberangel/.sdkman/bin/sdkman-init.sh" ]] && source "/home/cyberangel/.sdkman/bin/sdkman-init.sh"

# add alias
alias geeknote="python ~/geeknote/geeknote/geeknote.py"

# export android sdk path
export PATH=${PATH}:~/Android/Sdk/tools:~/Android/Sdk/platform-tools

# add genymotion path
PATH="$PATH":~/android-dev/genymotion

# add emacs-python path
PATH="$PATH":~/.local/bin

# export pyenv path
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"

# init pyenv-virtualenv
eval "$(pyenv virtualenv-init -)"

# init virtualenvwrapper
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/local/bin/virtualenvwrapper.sh
fi
