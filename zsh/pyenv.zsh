# pyenv

# Setup pyenv environment
export PYENV_ROOT=$HOME/.pyenv
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"

# Setup pyenv-virtualenv enviroment
eval "$(pyenv virtualenv-init -)"

# disable virtualenv prompt 
export PYENV_VIRTUALENV_DISABLE_PROMPT=1