package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installSpacemacs() {
	spacemacsDir := filepath.Join(os.Getenv("HONE"), ".emacs.d")
	spacemacsURL := "https://github.com/syl20bnr/spacemacs"

	msg := fmt.Sprintf("Install to %s", spacemacsDir)
	cmdRm := fmt.Sprintf("rm -rf %s", spacemacsDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", spacemacsURL, spacemacsDir)

	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallSpacemacs() {
	util.PrintInPurple("Spacemacs")
	installSpacemacs()
}
