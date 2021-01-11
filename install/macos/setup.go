package macos

func Setup() {
	InstallXCode()
	InstallHomebrew()
	InstallMisc()

	InstallEmacs()
	InstallTmux()
	InstallGhq()

	InstallSpacemacsRequirements()
	InstallPowerlevel10kRequirements()
}
