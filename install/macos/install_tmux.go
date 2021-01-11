package macos

import (
	"shunk031/dotfiles/install/common"
	"shunk031/dotfiles/install/util"
)

func InstallTmux() {
	util.PrintInPurple("tmux")

	brew := HomebrewCmd{}
	brew.Install("tmux", "tmux")
	brew.Install("reattach-to-user-namespace", "tmux (pasteboard)")

	common.InstallTPM()
}
