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
	    printf "   * %s\n" ${1}
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
sudo apt-get install athena-jot



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



nowinstall "Build and Install Emacs 24.5"
readonly EMACS_DIR=~/emacs-24.5
if [ -e $EMACS_DIR ]; then
    echo -e "\nEmacs 24.5 is already installed.\n"
else
    sudo apt-get install -y build-essential
    sudo apt-get install -y automake autoconf libgtk2.0-dev libtiff5-dev libgif-dev libjpeg-dev libpng12-dev libxpm-dev libncurses5-dev libxml2-dev gnutls-bin libcurl4-gnutls-dev libgnutls-dev
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



nowinstall "Install easystroke"
sudo apt-get install -y easystroke



nowinstall "Install zsh"
sudo apt-get install -y zsh
# chsh -s /bin/zsh



nowinstall "Install devilspie"
sudo apt-get install -y devilspie



nowsetup "Setup tmux" "tmux" "xsel"
sudo apt-get install -y tmux
sudo apt-get install -y xsel
