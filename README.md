# dotfiles

![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/figure1.png)

---

<p align="center">
  <a href="https://travis-ci.org/shunk031/dotfiles"><img src="https://travis-ci.org/shunk031/dotfiles.svg?branch=master" alt="Build Status"></a>
  <a href="http://spacemacs.org/"><img src="https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg" alt="spacemacs"></a>
  <a href="https://github.com/zsh-users/zsh"><img src="https://img.shields.io/badge/built%20with-zsh-black.svg" alt="zsh"></a>
  <a href="https://github.com/sorin-ionescu/prezto"><img src="https://img.shields.io/badge/built%20with-prezto-orange.svg" alt="prezto"></a>
  <a href="https://github.com/tmux/tmux"><img src="https://img.shields.io/badge/built%20with-tmux-green.svg" alt="tmux"></a>
</p>

---

## Installation

```shell
$ bash -c "$(curl -L http://shunk031.me/dotfiles/setup.sh)"
```

## Directory architecture

```
dotfiles
│
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
