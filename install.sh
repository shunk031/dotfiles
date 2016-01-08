#!/bin/sh

echo '

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

sudo apt-get update
sudo apt-get -y upgrade

echo '
======================================================================

			   Install texinfo

======================================================================
'
sudo apt-get install -y texinfo

echo '
======================================================================

			  Install latest git

======================================================================
'
sudo apt-get install python-software-properties
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update

sudo apt-get install -y git

echo '
======================================================================

			     Install zsh

======================================================================
'

sudo apt-get install -y zsh

echo '
======================================================================

			     Install pip

======================================================================
'
# sudo apt-get install -y pip


echo '
======================================================================

			     Install ESS

======================================================================
'
sudo apt-get install -y ess

echo '
======================================================================

			     Setup lintr

	 *** You will install the following applications ***

   * gfortran
   * liblapack-dev
   * libblas-dev

======================================================================
'
sudo apt-get install -y gfortran
sudo apt-get install -y liblapack-dev
sudo apt-get install -y libblas-dev

echo '
======================================================================

			     Setup knitr

	 *** You will install the following applications ***

   * libglu1-mesa-dev
   * libcurl4-openssl-dev
   
======================================================================
'
sudo apt-get install -y libglu1-mesa-dev
sudo apt-get install libcurl4-openssl-dev

echo '
======================================================================

			    Install JDK 8

======================================================================
'
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java8-installer

echo '
======================================================================

		     Install Tidy and Tidy-html5

======================================================================
'

sudo apt-get install -y Tidy

if [ -a tidy-html5 ]; then
    echo -e "\nTidy-html5 is already installed.\n"
    
else
    # tidy-html5をインストール
    git clone https://github.com/htacg/tidy-html5.git ~/
    cd ~/tidy-html5/build/cmake
    ./build-me.sh
    sudo make install
fi

echo '
======================================================================

		Setup Arduino Development Environment

	 *** You will install the following applications ***

   * arduino IDE
   * ino

======================================================================
'
sudo apt-get install -y arduino

if [ -a ino ]; then
    echo  -e "\nIno is already installed.\n"
    
else
    # Inoをインストール
    git clone git://github.com/amperka/ino.git ~/
    cd ino
    sudo make install
fi


echo '
======================================================================

			    Install migemo

======================================================================
'

sudo apt-get install -y cmigemo
sudo apt-get install -y migemo


echo '
======================================================================

		  Install ag - The Silver Searcher -

======================================================================
'
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:mizuno-as/silversearcher-ag
sudo apt-get update
sudo apt-get install -y silversearcher-ag

echo '
======================================================================

	     Setup Github Markdown writting environment

	 *** You will install the following applications ***

   * grip

======================================================================
'
# sudo pip install grip

echo '
======================================================================

			  Install emacs-mozc

======================================================================
'

sudo apt-get install -y emacs-mozc

echo '
======================================================================

		Setup Ricty - fonts for programming -

	 *** You will install the following applications ***

   * fontforge

======================================================================
'

sudo apt-get install -y fontforge

echo '
======================================================================

		  Setup Ruby Development Environment

	 *** You will install the following applications ***

   * Ruby
   * Redcarpet

======================================================================
'

sudo apt-get install -y ruby1.9.1-dev
sudo apt-get install -y ruby
sudo gem install redcarpet

echo '
======================================================================

		    Setup Tex writting environment

	 *** You will install the following applications ***

   * mercurial
   * texlive
   * texlive-lang-cjk
   * xdvik-ja
   * chktex (syntax checker)

======================================================================
'
# Yatex is managed by mercurial repository so install mercurial
sudo apt-get install -y mercurial

sudo apt-get install -y texlive
sudo apt-get install -y texlive-lang-cjk
sudo apt-get install -y xdvik-ja
sudo apt-get install -y chktex

echo '
======================================================================

	    Setup CSS Lint and Install some npm softwares

	 *** You will install the following applications ***

   * node.js
   * npm
   * CSS Lint
   * Browsersync

======================================================================
'

sudo apt-get install -y nodejs
sudo apt-get install -y npm

sudo npm install -g csslint
sudo npm install -g browser-sync

echo '
======================================================================

			   Install mplayer

======================================================================
'

sudo apt-get install -y mplayer

echo '
======================================================================

			   Install geeknote

======================================================================
'

git clone git://github.com/VitaliyRodnenko/geeknote.git ~/
cd geeknote
sudo python setup.py install

echo '
======================================================================

			     Setup tramp

	 *** You will install the following applications ***

   * autoconf
   * putty-tools

======================================================================
'

sudo apt-get install -y autoconf
sudo apt-get install -y putty-tools

echo '
======================================================================

		      Setup pyenv and virtualenv

	 *** You will install the following applications ***

   * pyenv
   * virtualenv

======================================================================
'
git clone https://github.com/yyuu/pyenv.git ~/.pyenv
git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
