package macos

type SetupMasOS interface {
	Install()
}

// Setup ...
func Setup() {

	setupers := []SetupMasOS{
		NewXCode(),
		NewHomebrew(),
		NewMisc(),
		NewEmacs(),
		NewTmux(),
		NewGhq(),
		NewSpacemacsRequirements(),
		NewPowerlevel10kRequirements(),
	}

	for _, setuper := range setupers {
		setuper.Install()
	}
}
