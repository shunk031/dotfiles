package macos

import "shunk031/dotfiles/install/util"

func installSourceCodeProFont() {
	brew := HomebrewCmd{}
	brew.Tap("homebrew/cask-fonts")
	brew.InstallWithCask("font-source-code-pro", "Source Code Pro")
}

func InstallSpacemacsRequirements() {
	util.PrintInPurple("Requirements for Spacemacs")
	installSourceCodeProFont()
}
