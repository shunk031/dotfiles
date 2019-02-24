#Setup goenv environment
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
export GOROOT=`go env GOROOT`

eval "$(goenv init -)"
