# dotfiles

![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/figure1.png)

[![spacemacs](https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg)](http://spacemacs.org/)
[![zsh](https://img.shields.io/badge/built%20with-zsh-black.svg)](https://github.com/zsh-users/zsh)
[![prezto](https://img.shields.io/badge/built%20with-prezto-orange.svg)](https://github.com/sorin-ionescu/prezto)
[![tmux](https://img.shields.io/badge/built%20with-tmux-green.svg)](https://github.com/tmux/tmux)

## Installation

```shell
$ bash -c "$(curl -L http://shunk031.me/dotfiles/setup.sh)"
```

## Directory architecture

```
dotfiles
│
├── .github             # The necessary repository for dotfiles is cloned here
├── .spacemacs.d        # Settings for Spacemacs
├── .xonsh              # Settings for Xonsh shell
├── .zsh                # Settings for Zsh shell
├── bin                 # Some original scripts and binaries
├── etc                 # Script files for setting
├── server              # Minimal dotfiles for server
├── Makefile            # Makefile for setting my dotfiles
├── .aspell.conf
├── .bash_profile
├── .bashrc
├── .gitconfig
├── .gitignore_global
├── .secret.zsh.example
├── .tmux-powerlinerc
├── .tmux.conf
├── .vimrc
├── .xonshrc
├── .zlogin
├── .zlogout
├── .zpreztorc
├── .zprofile
├── .zshenv
├── .zshrc
└── setup.sh
```
