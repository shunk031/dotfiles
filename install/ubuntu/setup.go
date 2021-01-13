package ubuntu

type SetupUbuntu interface {
	Install()
}

// Setup ...
func Setup() {

	setupers := []SetupUbuntu{
		NewMisc(),
		NewEmacs(),
		NewTmux(),
		NewGolang(),
		NewGhq(),
		NewSpacemacsRequirements(),
		NewPowerlevel10kRequirements(),
	}
	for _, setuper := range setupers {
		setuper.Install()
	}
}
