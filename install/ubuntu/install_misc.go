package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func (m Misc) installHadlint() {
	hadlintDir := filepath.Join(os.Getenv("DOTPATH"), "bin")
	hadlintFile := filepath.Join(hadlintDir, "hadlint")
	hadlintURL := "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-$(uname -s)-$(uname -m)"

	msg := fmt.Sprintf("Download and Install hadlint to %s", hadlintDir)
	cmdCurl := fmt.Sprintf("curl -sL -o %s %s", hadlintFile, hadlintURL)
	cmdChmod := fmt.Sprintf("chmod 700 %s", hadlintFile)

	cmd := fmt.Sprintf("%s; %s", cmdCurl, cmdChmod)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func (m Misc) InstallMisc() {

	m.installHadlint()

	apt := AptCmd{}

	pkgs := []string{
		"zsh",
		"build-essential",
		"cmake",
		"gcc",
		// for pyenv and pyenv-virtualenv
		"libssl-dev",
		"zlib1g-dev",
		"libbz2-dev",
		"libreadline-dev",
		"libsqlite3-dev",
		"wget",
		"curl",
		"llvm",
		"libncurses5-dev",
		"xz-utils",
		"tk-dev",
		"libxml2-dev",
		"libxmlsec1-dev",
		"libffi-dev",
		"liblzma-dev",
		// for rbenv and ruby-build
		"autoconf",
		"bison",
		"build-essential",
		"libssl-dev",
		"libyaml-dev",
		"libreadline6-dev",
		"zlib1g-dev",
		"libncurses5-dev",
		"libffi-dev",
		"libgdbm6",
		"libgdbm-dev",
		"libdb-dev",
	}

	pkgs = util.Unique(pkgs)
	for _, pkg := range pkgs {
		apt.Install(pkg, pkg)
	}
}

type Misc struct {
	util.Helper
}

func (m Misc) Install() {
	m.Print()

}

func NewMisc() SetupUbuntu {
	helper := util.Helper{"miscellaneous"}
	return Misc{helper}
}
