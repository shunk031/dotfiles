package macos

import "shunk031/dotfiles/install/util"

func (m Misc) installMisc() {

	brew := HomebrewCmd{}

	formulas := []string{
		"gcc",
		"ag",
		"autossh",
		"aspell",
		"cmake",
		"fontforge",
		"hadlint",
		"shellcheck",
		// for pyenv and pyenv-virtualenv
		"openssl",
		"readline",
		"sqlite3",
		"xz",
		"zlib",
		// for rbenv and ruby-build
		"libyaml",
		"libffi",
		// for spacemacs

	}

	formulas = util.Unique(formulas)
	for _, formula := range formulas {
		brew.Install(formula, formula)
	}

	caskFormulas := []string{
		"google-chrome",
		"slack",
		"visual-studio-code",
		"google-backup-and-sync",
		"google-japanese-ime",
		"spotify",
		"spectacle",
		"iterm2",
	}

	caskFormulas = util.Unique(caskFormulas)
	for _, formula := range caskFormulas {
		brew.InstallWithCask(formula, formula)
	}
}

type Misc struct {
	util.Helper
}

func (m Misc) Install() {
	m.Print()
	m.installMisc()
}

func NewMisc() SetupMasOS {
	helper := util.Helper{Name: "miscellaneous"}
	return Misc{helper}
}
