#!/bin/bash

# Specify Migu 1m font version
readonly MIGU_1M_VERSION="20150712"

# fontforge is needed to generate ricty
sudo apt-get install -y fontforge

# make working directory
mkdir -p $HOME/gen-ricty
echo "make working directory to ~/gen-ricty"

# download Inconsolata fonts from github
wget https://github.com/google/fonts/raw/master/ofl/inconsolata/Inconsolata-Regular.ttf -P $HOME/gen-ricty
wget https://github.com/google/fonts/raw/master/ofl/inconsolata/Inconsolata-Bold.ttf -P $HOME/gen-ricty
echo "downloaded Inconsolata fonts"

# download migu-1m fonts
wget --trust-server-names 'https://osdn.jp/frs/redir.php?m=iij&f=%2Fmix-mplus-ipa%2F63545%2Fmigu-1m-20150712.zip' -O $HOME/gen-ricty/migu-1m.zip

echo "downloaded migu-1m fonts"

# change working directory
cd $HOME/gen-ricty

# unzip "migu-1m" zip file
unzip migu-1m.zip

# copy some migu-1m fonts
cp -f migu-1m-$MIGU_1M_VERSION/*.ttf $HOME/gen-ricty

# download github ricty repository
wget http://www.rs.tus.ac.jp/yyusa/ricty/ricty_generator.sh -P $HOME/gen-ricty

# run ricty_generator.sh
sh ricty_generator.sh auto

# make ".fonts" directory
mkdir -p ~/.fonts

# copy Ricty fonts and install
cp -f Ricty*.ttf ~/.fonts/
fc-cache -vf

# clone vim-powerline repository
git clone https://github.com/Lokaltog/vim-powerline.git

# create ricty for powerline and move .fonts directory
fontforge -lang=py -script ./vim-powerline/fontpatcher/fontpatcher $HOME/.fonts/Ricty-Regular.ttf
fontforge -lang=py -script ./vim-powerline/fontpatcher/fontpatcher $HOME/.fonts/Ricty-Bold.ttf
mv Ricty-Regular-Powerline.ttf ~/.fonts
mv Ricty-Bold-Powerline.ttf ~/.fonts

# remove working directory
rm -rf $HOME/gen-ricty
