package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installPyenv() {
	pyenvDir := filepath.Join(os.Getenv("HOME"), ".pyenv")
	pyenvURL := "https://github.com/yyuu/pyenv.git"

	msg := fmt.Sprintf("Install to %s", pyenvDir)
	cmdRm := fmt.Sprintf("rm -rf %s", pyenvDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", pyenvURL, pyenvDir)

	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}

}

func installPyenvVirtualenv() {
	pyenvVirtualenvDir := filepath.Join(os.Getenv("HOME"), ".pyenv", "plugins", "pyenv-virtualenv")
	pyenvVirtualenvURL := "https://github.com/yyuu/pyenv-virtualenv.git"

	msg := fmt.Sprintf("Install to %s", pyenvVirtualenvDir)
	cmdRm := fmt.Sprintf("rm -rf %s", pyenvVirtualenvDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", pyenvVirtualenvURL, pyenvVirtualenvDir)

	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallPyenv() {
	util.PrintInPurple("For pyenv and pyenv-virtualenv")
	installPyenv()
	installPyenvVirtualenv()

}
