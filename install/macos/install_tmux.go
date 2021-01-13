package macos

import (
	"shunk031/dotfiles/install/common"
	"shunk031/dotfiles/install/util"
)

func (t Tmux) installTmux() {

	brew := HomebrewCmd{}
	brew.Install("tmux", "tmux")
	brew.Install("reattach-to-user-namespace", "tmux (pasteboard)")

	tpm := common.NewTpm()
	tpm.Install()
}

type Tmux struct {
	util.Helper
}

func (t Tmux) Install() {
	t.Print()
	t.installTmux()
}

func NewTmux() SetupMasOS {
	helper := util.Helper{"tmux"}
	return Tmux{helper}
}
