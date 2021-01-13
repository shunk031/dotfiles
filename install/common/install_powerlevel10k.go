package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installPowerlevel10k() {
	p10kDir := filepath.Join(os.Getenv("HOME"), ".zprezto", "modules", "prompt", "external", "powerlevel10k")
	p10kURL := "https://github.com/romkatv/powerlevel10k.git"

	msg := fmt.Sprintf("Clone to %s", p10kDir)
	cmdRm := fmt.Sprintf("rm -rf %s", p10kDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", p10kURL, p10kDir)

	err := util.Execute(msg, fmt.Sprintf("%s; %s", cmdRm, cmdGit))
	if err != nil {
		log.Fatal(err)
	}
}

func InstallPowerlevel10k() {
	util.PrintInPurple("For powerlevel10k")
	installPowerlevel10k()
}
