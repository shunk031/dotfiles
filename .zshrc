# zshrc

source-safe () { if [ -f "$1" ]; then source "$1"; fi }

#
# PATHs
#

source-safe "${HOME}/.zsh/path.sh"

#
# *envs
#

source-safe "${HOME}/.zsh/pyenv.sh"
source-safe "${HOME}/.zsh/rbenv.sh"
source-safe "${HOME}/.zsh/goenv.sh"

#
# aliases
#

source-safe "${HOME}/.zsh/alias.sh"

#
# prezto
#

source-safe "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"

#
# powerlevel9k
#

source-safe "${HOME}/.zsh/powerlevel9k.sh"

#
# secrets
#

source-safe "{HOME}/.secret.zsh"

#
# fzf
#

source-safe "${HOME}/.fzf.zsh"

#
# Auto load some functions
#

autoload -Uz dev
