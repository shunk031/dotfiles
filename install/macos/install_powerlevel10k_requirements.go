package macos

import "shunk031/dotfiles/install/util"

func installNerdFont() {
	brew := HomebrewCmd{}
	brew.Tap("homebrew/cask-fonts")
	brew.InstallWithCask("font-hack-nerd-font", "Nerd Font")
}

func InstallPowerlevel10kRequirements() {
	util.PrintInPurple("Requirements for powerlevel10k")
	installNerdFont()
}
