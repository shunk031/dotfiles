package ubuntu

import (
	"shunk031/dotfiles/install/common"
	"shunk031/dotfiles/install/util"
)

func (t Tmux) installTmux() {
	util.PrintInPurple("tmux")

	apt := AptCmd{}
	apt.Install("tmux", "tmux")
	apt.Install("xsel", "tmux (pasteboard)")

	common.InstallTPM()
}

type Tmux struct {
	util.Helper
}

func (t Tmux) Install() {
	t.Print()
	t.installTmux()
}

func NewTmux() SetupUbuntu {
	helper := util.Helper{"tmux"}
	return Tmux{helper}
}
