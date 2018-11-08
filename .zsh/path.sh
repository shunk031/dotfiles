# for local bin
export PATH=${PATH}:~/.local/bin

# for /usr/local/bin
export PATH=${PATH}:/usr/local/bin

# for ~/bin
export PATH=${PATH}:~/bin

# for golang
export PATH=${PATH}:/usr/local/go/bin
export GOPATH=$HOME/Programming/go
export PATH=${PATH}:$GOPATH/bin
export GOROOT=`go env GOROOT`

# for Android SDK
export PATH=${PATH}:~/Android/Sdk/tools:~/Android/Sdk/platform-tools

# for my scripts
export PATH=${PATH}:~/dotfiles/emacs.d/etc
