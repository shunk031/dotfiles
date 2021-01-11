package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installPrezto() {
	zdotDir := os.Getenv("ZDOTDIR")
	if zdotDir == "" {
		zdotDir = os.Getenv("HOME")
	}
	preztoDir := filepath.Join(zdotDir, ".zprezto")
	preztoURL := "https://github.com/sorin-ionescu/prezto.git"

	msg := fmt.Sprintf("Install to %s", preztoDir)
	cmdRm := fmt.Sprintf("rm -rf %s", preztoDir)
	cmdGit := fmt.Sprintf("git clone --quiet --recursive %s %s", preztoURL, preztoDir)

	err := util.Execute(msg, "/bin/bash", "-c", fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}

}

func InstallPrezto() {
	util.PrintInPurple("For Prezto")
	installPrezto()
}
