package common

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/util"
)

func installTmuxMemCPULoad() {
	dir := filepath.Join(os.Getenv("DOTPATH"), ".github", "tmux-mem-cpu-load")
	URL := "https://github.com/thewtex/tmux-mem-cpu-load.git"

	msg := "Install tmux mem cpu load"
	cmdRm := fmt.Sprintf("rm -rf %s", dir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", URL, dir)
	cmdCd := fmt.Sprintf("cd %s", dir)
	cmdCMake := "cmake ."
	cmdMakeInstall := "sudo make install"

	cmd := fmt.Sprintf("%s; %s; %s; %s; %s", cmdRm, cmdGit, cmdCd, cmdCMake, cmdMakeInstall)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func installTpm() {
	tpmDir := filepath.Join(os.Getenv("HOME"), ".tmux", "plugins", "tpm")
	tpmURL := "https://github.com/tmux-plugins/tpm"

	msg := fmt.Sprintf("Install tpm (tmux plugin manager) to %s", tpmDir)
	cmdRm := fmt.Sprintf("rm -rf %s", tpmDir)
	cmdGit := fmt.Sprintf("git clone --quiet %s %s", tpmURL, tpmDir)

	cmd := fmt.Sprintf("%s; %s", cmdRm, cmdGit)
	err := util.Execute(msg, cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func installTpmPlugin() {
	tpmDir := filepath.Join(os.Getenv("HOME"), ".tmux", "plugins", "tpm")
	scriptPath := filepath.Join(tpmDir, "scripts", "install_plugins.sh")

	cmd := fmt.Sprintf("bash %s", scriptPath)
	err := util.Execute("Install tpm plugins", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallTPM() {
	util.PrintInPurple("For tpm")

	installTmuxMemCPULoad()
	installTpm()
	installTpmPlugin()
}
