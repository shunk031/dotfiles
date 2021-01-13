package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

type Fzf struct {
	util.Helper
}

func (f Fzf) Install() {
	f.Print()

	f.installFzf()
}

func (f Fzf) installFzf() {
	fzfDir := filepath.Join(os.Getenv("HOME"), ".fzf")
	fzfURL := "https://github.com/junegunn/fzf.git"

	msg := fmt.Sprintf("Clone to %s", fzfDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fzfDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", fzfURL, fzfDir)

	err := util.Execute(msg, fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}

	cmdInstall := filepath.Join(fzfDir, "install")
	cmd := fmt.Sprintf("%s --key-bindings --completion --no-update-rc", cmdInstall)
	err = util.Execute("Install", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func NewFzf() SetupCommon {
	helper := util.Helper{Name: "fzf"}
	return Fzf{helper}
}
