package macos

// Setup ...
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
