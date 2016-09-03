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

echo "$installdotsh_logo"

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

			     Install pip

======================================================================
'
sudo apt-get install -y python-pip


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

# R -q -e "install.packages('lintr', dependencies=TRUE)"

echo '
======================================================================

			     Setup knitr

	 *** You will install the following applications ***

   * libglu1-mesa-dev
   * libcurl4-openssl-dev
   
======================================================================
'
sudo apt-get install -y libglu1-mesa-dev
sudo apt-get install -y libcurl4-openssl-dev

# R -q -e "install.packages('kintr', dependencies=TRUE)"

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

readonly TIDYHTML5_DIR=~/tidy-html5

if [ -e $TIDYHTML5_DIR ]; then
    echo -e "\nTidy-html5 is already installed.\n"
else
    # clone and install tidy-html
    git clone https://github.com/htacg/tidy-html5.git $TIDYHTML5_DIR
    cd $TIDYHTML5_DIR/build/cmake
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
# sudo apt-get install -y arduino

# readonly INO_DIR=~/ino

# if [ -e $INO_DIR ]; then
#     echo -e "\nIno is already installed.\n"
# else
#     # install Ino
#     git clone https://github.com/amperka/ino.git $INO_DIR
#     cd $INO_DIR
#     sudo make install
# fi


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
sudo pip install grip

echo '
======================================================================

			  Install emacs-mozc

======================================================================
'

sudo apt-get install -y emacs-mozc

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

readonly GEEKNOTE_DIR=~/geeknote

if [ -e $GEEKNOTE_DIR ]; then
    echo -e "\ngeeknote is already installed.\n"
else
    # clone and install geeknote
    git clone git://github.com/VitaliyRodnenko/geeknote.git $GEEKNOTE_DIR
    cd $GEEKNOTE_DIR
    sudo python setup.py install
fi

echo '
======================================================================

			 Setup Emacs "tramp"

	 *** You will install the following applications ***

   * autoconf
   * putty-tools

======================================================================
'

sudo apt-get install -y autoconf
sudo apt-get install -y putty-tools

echo '
======================================================================

		      Setup pyenv and pyenv-virtualenv

	 *** You will install the following applications ***

   * pyenv
   * pyenv-virtualenv
   * pyenv-pip-rehash

   * python tkinter

======================================================================
'

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

echo '
======================================================================

			   Install PHP5-CLI

======================================================================
'

sudo apt-get install -y php5-cli

echo '
======================================================================

		   Download My Emacs configuration

======================================================================
'

readonly DOTEMACS_DIR=~/emacs.d

# Clone my emacs.d
if [ -e $DOTEMACS_DIR ];then
    echo -e "\nemacs.d is already cloned.\n"
else
    git clone https://github.com/shunk031/emacs.d.git $DOTEMACS_DIR
fi

echo '
======================================================================

			    Install Aspell

======================================================================
'

sudo apt-get install -y aspell aspell-en

echo '
======================================================================

			    Install cpanm

======================================================================
'

sudo apt-get install -y cpanminus

echo '
======================================================================

			   Install graphviz

======================================================================
'

sudo apt-get install -y graphviz
