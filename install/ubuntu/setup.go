package ubuntu

// Setup ...
func Setup() {
	InstallMisc()
	InstallEmacs()
	InstallTmux()

	InstallGolang()
	InstallGhq()

	InstallSpacemacsRequirements()
	InstallPowerlevel10kRequirements()
}
