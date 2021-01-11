# for homebrew
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"ex
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# for local bin
export PATH=${PATH}:~/.local/bin

# for /usr/local/bin
export PATH=${PATH}:/usr/local/bin

# for ~/bin
export PATH=${PATH}:~/bin

## for zshtools
fpath=(~/bin $fpath)

# for golang
export PATH=${PATH}:/usr/local/go/bin
export GOPATH=$HOME/ghq
export PATH=${PATH}:$GOPATH/bin
export GOROOT=`go env GOROOT`
