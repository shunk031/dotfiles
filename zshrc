#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/cyberangel/.sdkman"
[[ -s "/home/cyberangel/.sdkman/bin/sdkman-init.sh" ]] && source "/home/cyberangel/.sdkman/bin/sdkman-init.sh"

# add alias
alias geeknote="python ~/geeknote/geeknote/geeknote.py"
alias browser-sync-start="browser-sync start --server --files \"**/*\""

# export android sdk path
export PATH=${PATH}:~/Android/Sdk/tools:~/Android/Sdk/platform-tools

# add genymotion path
PATH="$PATH":~/android-dev/genymotion

# add emacs-python path
PATH="$PATH":~/.local/bin

# add composer path
PATH="$PATH"~/.composer/vender/bin

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Source zsh-python-prompt
source ~/dotfiles/zsh-python-prompt/zshrc.zsh
