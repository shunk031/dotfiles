package ubuntu

import (
	"shunk031/dotfiles/install/common"
	"shunk031/dotfiles/install/util"
)

func InstallTmux() {
	util.PrintInPurple("tmux")

	apt := AptCmd{}
	apt.Install("tmux", "tmux")
	apt.Install("xsel", "tmux (pasteboard)")

	common.InstallTPM()
}
