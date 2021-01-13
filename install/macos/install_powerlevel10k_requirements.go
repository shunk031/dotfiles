package macos

import "shunk031/dotfiles/install/util"

func (p Powerlevel10kRequirements) installNerdFont() {
	brew := HomebrewCmd{}
	brew.Tap("homebrew/cask-fonts")
	brew.InstallWithCask("font-hack-nerd-font", "Nerd Font")
}

type Powerlevel10kRequirements struct {
	util.Helper
}

func (p Powerlevel10kRequirements) Install() {
	p.Print()
	p.installNerdFont()
}

func NewPowerlevel10kRequirements() SetupMasOS {
	helper := util.Helper{"powerlevel10k requirements"}
	return Powerlevel10kRequirements{helper}
}
