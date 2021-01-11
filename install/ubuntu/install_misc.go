package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installHadlint() {
	hadlintDir := filepath.Join(os.Getenv("DOTPATH"), "bin")
	hadlintFile := filepath.Join(hadlintDir, "hadlint")
	hadlintURL := "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-$(uname -s)-$(uname -m)"

	msg := fmt.Sprintf("Download and Install hadlint to %s", hadlintDir)
	cmdCurl := fmt.Sprintf("curl -sL -o %s %s", hadlintFile, hadlintURL)
	cmdChmod := fmt.Sprintf("chmod 700 %s", hadlintFile)

	cmd := fmt.Sprintf("%s; %s", cmdCurl, cmdChmod)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallMisc() {
	util.PrintInPurple("Miscellaneous")
	installHadlint()

	apt := AptCmd{}

	pkgs := []string{
		"zsh",
		"gcc",
		"build-essential",
		"cmake",
	}

	pkgs = util.Unique(pkgs)
	for _, pkg := range pkgs {
		apt.Install(pkg, pkg)
	}
}
