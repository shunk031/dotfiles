# my functions

# load xmodmap function
load_xmod_map(){
    xmodmap ~/.Xmodmap
    echo "Now loaded Xmod map"
}

# run both python 2 and 3 version
python6() {
    echo -e "run script in python 2 env."
    pyenv global search-tec2
    python $1

    echo -e "run script in python 3 env."
    pyenv global search-tec3
    python $1
}

fix_zsh_history() {
    mv ~/.zhistory ~/.zhistory_bad
    strings .zhistory_bad > .zhistory
    fc -R ~/.zhistory
    rm ~/.zhistory_bad
}
