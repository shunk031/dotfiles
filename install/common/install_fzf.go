package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installFzf() {
	fzfDir := filepath.Join(os.Getenv("HOME"), ".fzf")
	fzfURL := "https://github.com/junegunn/fzf.git"

	msg := fmt.Sprintf("Clone to %s", fzfDir)
	cmdRm := fmt.Sprintf("rm -rf %s", fzfDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", fzfURL, fzfDir)

	err := util.Execute(msg, "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}

	cmdInstall := fmt.Sprintf(filepath.Join(fzfDir, "install"))
	err = util.Execute("Install", cmdInstall, "--key-bindings", "--completion", "--no-update-rc")
	if err != nil {
		log.Fatal(err)
	}

}

func InstallFzf() {
	util.PrintInPurple("For fzf")
	installFzf()
}
