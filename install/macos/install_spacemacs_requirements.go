package macos

import "shunk031/dotfiles/install/util"

func (s SpacemacsRequirements) installSourceCodeProFont() {
	brew := HomebrewCmd{}
	brew.Tap("homebrew/cask-fonts")
	brew.InstallWithCask("font-source-code-pro", "Source Code Pro")
}

type SpacemacsRequirements struct {
	util.Helper
}

func (s SpacemacsRequirements) Install() {
	s.Print()
	s.installSourceCodeProFont()
}

func NewSpacemacsRequirements() SetupMasOS {
	helper := util.Helper{Name: "spacemacs requirements"}
	return SpacemacsRequirements{helper}
}
