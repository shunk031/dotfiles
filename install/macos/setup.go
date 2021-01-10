package macos

func Setup() {
	InstallXCode()
	InstallHomeBrew()
	InstallMisc()

	InstallEmacs()
	InstallTmux()
	InstallGhq()
	InstallVscode()

	InstallPyenvRequirements()
	InstallRbenvRequirements()

	InstallSpacemacsRequirements()
	InstallPowerlevel10kRequirements()
}
