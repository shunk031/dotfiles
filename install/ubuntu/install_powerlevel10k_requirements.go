package ubuntu

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installNerdFont() {
	fontDir := filepath.Join(os.Getenv("HOME"), ".local", "share", "fonts")
	fontURL := "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/RobotoMono/Medium/complete/Roboto%20Mono%20Medium%20Nerd%20Font%20Complete%20Mono.ttf"
	fontName := "Roboto Mono Nerd Font Complete Mono.ttf"

	msg := fmt.Sprintf("Install font: Roboto Mono Nerd Font Complete Mono")
	cmdMkdir := fmt.Sprintf("mkdir -p %s", fontDir)
	cmdCd := fmt.Sprintf("cd %s", fontDir)
	cmdCurl := fmt.Sprintf("curl -fLo %s %s", fontName, fontURL)

	cmd := fmt.Sprintf("%s; %s; %s", cmdMkdir, cmdCd, cmdCurl)
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallPowerlevel10kRequirements() {
	util.PrintInPurple("Requirements for powerlevel10k")
	installNerdFont()
}
