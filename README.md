![](https://raw.githubusercontent.com/shunk031/dotfiles/master/.github/header.png)

---

<p align="center">
  <a href="https://github.com/shunk031/dotfiles/actions?query=workflow%3A%22Snippet+install%22"><img src="https://github.com/shunk031/dotfiles/workflows/Snippet%20install/badge.svg" alt="Build Status"></a>
  <a href="http://spacemacs.org/"><img src="https://cdn.rawgit.com/syl20bnr/spacemacs/442d025779da2f62fc86c2082703697714db6514/assets/spacemacs-badge.svg" alt="spacemacs"></a>
  <a href="https://github.com/zsh-users/zsh"><img src="https://img.shields.io/badge/built%20with-zsh-black.svg" alt="zsh"></a>
  <a href="https://github.com/sorin-ionescu/prezto"><img src="https://img.shields.io/badge/built%20with-prezto-orange.svg" alt="prezto"></a>
  <a href="https://github.com/tmux/tmux"><img src="https://img.shields.io/badge/built%20with-tmux-green.svg" alt="tmux"></a>
</p>

---

# 📂 dotfiles

- Managed with [`chezmoi 🏠`](https://www.chezmoi.io/) and MacOS & Ubuntu.

## 📥 Setup

To set up the dotfiles run the appropriate snippet in the terminal:

### 💻 `MacOS` [![Build Status](https://github.com/shunk031/dotfiles/workflows/MacOS/badge.svg)](https://github.com/shunk031/dotfiles/actions?query=workflow%3AMacOS)

```console
bash -c "$(curl -LsS http://shunk031.me/dotfiles/setup.sh)"
```

### 🖥️ `Ubuntu` [![Build Status](https://github.com/shunk031/dotfiles/workflows/Ubuntu/badge.svg)](https://github.com/shunk031/dotfiles/actions?query=workflow%3AUbuntu)

```console
bash -c "$(wget -qO - http://shunk031.me/dotfiles/setup.sh)"
```

## 🛠️ Update & Test 🧪

## 💾 Test on the local machine

- The following command will execute the [`chezmoi apply`](https://www.chezmoi.io/reference/commands/apply/) command as soon as the file is modified using [`watchexec`](https://github.com/watchexec/watchexec).

```console
make watch
```

## 🐳 Test on Docker container

- Launch the test environment using Docker 🐳.

```shell
make docker

# docker run -it -v "$(pwd):/home/$(whoami)/.local/share/chezmoi" dotfiles /bin/bash --login
# shunk031@5f93d270cb51:~$ chezmoi init --apply
```

- Run the [`chezmoi init --apply`](https://www.chezmoi.io/user-guide/setup/#use-a-hosted-repo-to-manage-your-dotfiles-across-multiple-machines) command to verify that the system is set up correctly.

```shell
shunk031@5f93d270cb51:~$ chezmoi init --apply
```

## 👏 Acknowledgements

Inspiration and code was taken from many sources, including:

- [twpayne/chezmoi](https://github.com/twpayne/chezmoi) from [twpayne](https://github.com/twpayne).
- [alrra/dotfiles](https://github.com/alrra/dotfiles): macOS / Ubuntu dotfiles from [@alrra](https://github.com/alrra).
- [b4b4r07/dotfiles](https://github.com/b4b4r07/dotfiles): A repository that gathered files starting with dot from [@b4b4r07](https://github.com/b4b4r07).
- [da-edra/dotfiles](https://github.com/da-edra/dotfiles): Arch Linux config from [@da-edra](https://github.com/da-edra).

## 📝 License

The code is available under the [MIT license](https://github.com/shunk031/dotfiles/blob/master/LICENSE).
