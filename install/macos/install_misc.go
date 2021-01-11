package macos

import "shunk031/dotfiles/install/util"

func unique(strSlice []string) []string {
	keys := make(map[string]bool)
	list := []string{}
	for _, entry := range strSlice {
		if _, value := keys[entry]; !value {
			keys[entry] = true
			list = append(list, entry)
		}
	}
	return list
}

func InstallMisc() {
	util.PrintInPurple("Miscellaneous")

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

	formulas = unique(formulas)
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

	caskFormulas = unique(caskFormulas)
	for _, formula := range caskFormulas {
		brew.InstallWithCask(formula, formula)
	}
}
