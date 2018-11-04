PYENV_DIR=${HOME}/.pyenv
PYENV_VIRTUALENV_DIR=${PYENV_DIR}/plugins/pyenv-virtualenv

if [ ! -e "$PYENV_DIR" ]; then
    git clone https://github.com/yyuu/pyenv.git $PYENV_DIR
fi

if [ ! -e "$PYENV_VIRTUALENV_DIR" ]; then
    git clone https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
fi

# Setup pyenv environment
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Setup pyenv-virtualenv enviroment
eval "$(pyenv virtualenv-init -)"

# disable virtualenv prompt
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
