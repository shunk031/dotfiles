package ubuntu

// Setup ...
func Setup() {
	InstallMisc()
	InstallEmacs()
	InstallTmux()

	InstallGolang()
	InstallGhq()

	InstallPyenvRequirements()
	installRbenvRequirements()

	InstallSpacemacsRequirements()
	InstallPowerlevel10kRequirements()

}
