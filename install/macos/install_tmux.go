package macos

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"shunk031/dotfiles/install/common"
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
	err := util.Execute(msg, "/bin/bash", "-c", cmd)
	if err != nil {
		log.Fatal(err)
	}
}

func InstallTmux() {
	util.PrintInPurple("tmux")

	brew := HomebrewCmd{}
	brew.Install("tmux", "tmux")
	brew.Install("reattach-to-user-namespace", "tmux (pasteboard)")

	installTmuxMemCPULoad()
	common.InstallTPM()
}
