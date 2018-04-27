#!/bin/bash

installdotsh_logo='

    /$$                       /$$               /$$ /$$               /$$      
   |__/                      | $$              | $$| $$              | $$      
    /$$ /$$$$$$$   /$$$$$$$ /$$$$$$    /$$$$$$ | $$| $$      /$$$$$$$| $$$$$$$ 
   | $$| $$__  $$ /$$_____/|_  $$_/   |____  $$| $$| $$     /$$_____/| $$__  $$
   | $$| $$  \ $$|  $$$$$$   | $$      /$$$$$$$| $$| $$    |  $$$$$$ | $$  \ $$
   | $$| $$  | $$ \____  $$  | $$ /$$ /$$__  $$| $$| $$     \____  $$| $$  | $$
   | $$| $$  | $$ /$$$$$$$/  |  $$$$/|  $$$$$$$| $$| $$ /$$ /$$$$$$$/| $$  | $$
   |__/|__/  |__/|_______/    \___/   \_______/|__/|__/|__/|_______/ |__/  |__/

   *** This is application install script ***
   Install the required application
'

nowinstall () {
    n=70
    jot -b = -s "" ${n}
    printf "\n%*s\n\n" $(((${#1}+${n})/2)) "$1"
    jot -b = -s "" ${n}

}

nowsetup () {
    description='*** You will install the following applications ***'
    n=70
    jot -b = -s "" ${n}
    printf "\n%*s\n\n" $(((${#1}+${n})/2)) "$1"
    printf "\n%*s\n\n" $(((${#description}+${n})/2)) "$description"
    for i in `seq 1 ${#}`
    do
	if [ $i -gt 1 ]; then
	    printf "   * %s\n" "${1}"
	    shift
	else
	    shift
	fi
    done
    echo ""
    jot -b = -s "" ${n}
}

echo "$installdotsh_logo"

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y athena-jot
sudo apt-get install -y libgtop-2.0-10



nowinstall "Setup Time Date control"
sudo timedatectl set-local-rtc 1


nowinstall "Japanese Input Environment"
sudo apt-get install -y fcitx fcitx-mozc fcitx-libs-qt fcitx-libs-qt5 fcitx-frontend-qt5 fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-config-gtk fcitx-tools fcitx-ui-classic mozc-utils-gui



nowinstall "Change English name directory"
env LANGUAGE=C LC_MESSAGES=C xdg-user-dirs-gtk-update
echo "Now changed!"



nowinstall "Intall guake terminal"
sudo apt-get install -y guake



nowinstall "Install Gparted"
sudo apt-get install -y gparted



nowinstall "Install grub-customizer"
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
sudo apt-get update && sudo apt-get install -y grub-customizer



nowinstall "Install cmake"
sudo apt-get install -y cmake


nowinstall "Build and Install Emacs 24.5"
readonly EMACS_DIR=~/emacs-24.5
if [ -e $EMACS_DIR ]; then
    echo -e "\nEmacs 24.5 is already installed.\n"
else
    sudo apt-get install -y build-essential
    sudo apt-get install -y automake autoconf libgtk2.0-dev libtiff-dev libgif-dev libjpeg-dev libpng-dev libxpm-dev libncurses5-dev libxml2-dev gnutls-bin libcurl4-gnutls-dev libgnutls-dev
    sudo apt-get install xfonts-100dpi xfonts-75dpi xfonts-shinonome
    wget http://ftp.gnu.org/gnu/emacs/emacs-24.5.tar.gz
    tar -xzvf emacs-24.5.tar.gz
    rm emacs-24.5.tar.gz
    cd emacs-24.5
    ./configure
    make
    sudo make install
fi



nowinstall "Install Cairo-dock"
sudo apt-add-repository -y ppa:cairo-dock-team/ppa
sudo apt-get update && sudo apt-get install -y cairo-dock cairo-dock-plug-ins



nowinstall "Install and set Git"
sudo apt-get install python-software-properties
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update && sudo apt-get install -y git
git config --global user.name "Shunsuke KITADA"
git config --global user.email "septemtrio.ager@gmail.com"
git config --global color.ui auto
git config --global "url.git@github.com:.pushinsteadof" "https://github.com/"



nowinstall "Install dconf-editor and set some key"
sudo apt-get install -y dconf-editor
gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs'
gsettings set org.cinnamon.desktop.interface gtk-key-theme 'Emacs'
gsettings set org.gnome.settings-daemon.plugins.power use-time-for-policy false
gsettings set org.gnome.settings-daemon.plugins.power percentage-critical 10
gsettings set org.gnome.settings-daemon.plugins.power percentage-action 9



nowinstall "Install easystroke"
sudo apt-get install -y easystroke



nowinstall "Install zsh"
sudo apt-get install -y zsh
# chsh -s /bin/zsh



nowinstall "Install devilspie"
sudo apt-get install -y devilspie



nowinstall "Install texinfo"
sudo apt-get install -y texinfo



nowinstall "Install pip"
sudo apt-get install -y python-pip



# nowinstall "Install JDK 8"
# sudo add-apt-repository -y ppa:webupd8team/java
# sudo apt-get update
# sudo apt-get install -y oracle-java8-installer



nowinstall "Install migemo"
sudo apt-get install -y cmigemo
sudo apt-get install -y migemo



nowinstall "Install ag - The Silver Searcher -"
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:mizuno-as/silversearcher-ag
sudo apt-get update
sudo apt-get install -y silversearcher-ag



nowinstall "Install Emacs-mozc"
sudo apt-get install -y emacs-mozc



nowinstall "Install PHP5-CLI"
sudo apt-get install -y php5-cli



nowinstall "Install Aspell"
sudo apt-get install -y aspell aspell-en



nowinstall "Install graphviz"
sudo apt-get install -y graphviz



nowinstall "Install ntfs-config"
sudo apt-get install -y ntfs-config



nowsetup "Setup tmux" "tmux" "xsel"
sudo apt-get install -y tmux
sudo apt-get install -y xsel


nowsetup "Setup tmux environment" "tmux plugin manager" "tmux-resurrect" "tmux-continuum"
readonly TMUX_PLUGIN_DIR=~/.tmux/plugins/tpm
if [ -e $TMUX_PLUGIN_DIR ]; then
    echo -e '\ntmux plugin manager is already cloned.\n'
else
    git clone https://github.com/tmux-plugins/tpm $TMUX_PLUGIN_DIR
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
fi



nowinstall "Install tmux-mem-cpu-load"
TMUX_MEM_CPU_LOAD_COMMAND=tmux-mem-cpu-load
if [ `which $TMUX_MEM_CPU_LOAD_COMMAND` ]; then
    echo -e "\ntmux-mem-cpu-load is already installed.\n"
else
    git clone https://github.com/thewtex/tmux-mem-cpu-load.git
    cd tmux-mem-cpu-load
    cmake .
    make
    sudo make install
fi



nowsetup "Setup lintr" "gfortran" "liblapack-dev" "libblas-dev"
sudo apt-get install -y gfortran
sudo apt-get install -y liblapack-dev
sudo apt-get install -y libblas-dev



nowsetup "Setup knitr" "libglu1-mesa-dev" "libcurl4-openssl-dev"
sudo apt-get install -y libglu1-mesa-dev
sudo apt-get install -y libcurl4-openssl-dev



nowsetup "Setup Github Markdown writting environment" "grip"
sudo pip install grip



nowsetup "Setup Tex writting environment" "mercurial" "texlive" "texlive-lang-cjk" "xdvik-ja" "chktex (syntax checker)"
# Yatex is managed by mercurial repository so install mercurial
sudo apt-get install -y mercurial
sudo apt-get install -y texlive
sudo apt-get install -y texlive-lang-cjk
sudo apt-get install -y xdvik-ja
sudo apt-get install -y chktex
sudo apt-get install -y texlive-full



nowsetup "Setup CSS Lint and Install some npm softwares" "node.js" "npm" "CSS Lint" "Browsersync"
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo npm install -g csslint
sudo npm install -g browser-sync



nowsetup "Setup Emacs tramp" "autoconf" "putty-tools"
sudo apt-get install -y autoconf
sudo apt-get install -y putty-tools



nowsetup "Setup pyenv and pyenv-virtualenv" "pyenv" "pyenv-virtualenv" "pyenv-pip-rehash" "python tkinter"
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils

readonly PYENV_DIR=~/.pyenv
readonly PYENV_VIRTUALENV_DIR=~/.pyenv/plugins/pyenv-virtualenv
readonly PYENV_PIP_REFRESH_DIR=~/.pyenv/plugins/pyenv-pip-rehash

# Clone "pyenv"
if [ -e $PYENV_DIR ]; then
    echo -e "\npyenv is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv.git $PYENV_DIR
fi

# Clone pyenv plugin "pyenv-virtualenv"
if [ -e $PYENV_VIRTUALENV_DIR ]; then
    echo -e "\npyenv-virtualenv is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv-virtualenv.git $PYENV_VIRTUALENV_DIR
fi

# Clone pyenv plugin "pyenv-pip-refresh"
if [ -e $PYENV_PIP_REFRESH_DIR ]; then
    echo -e "\npyenv-pip-refresh is already cloned.\n"
else
    git clone https://github.com/yyuu/pyenv-pip-rehash.git $PYENV_PIP_REFRESH_DIR
fi

sudo apt-get install -y tk-dev
