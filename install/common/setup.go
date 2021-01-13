package common

type SetupCommon interface {
	Install()
}

// Setup ...
func Setup() {

	setupers := []SetupCommon{
		NewPowerlineFont(),
		NewFzf(),
		NewZplugin(),
		NewPrezto(),
	}

	for _, setuper := range setupers {
		setuper.Install()
	}

	// // for powerline
	// InstallPowerlineFont()
	// // for fzf
	// InstallFzf()

	// // for zplugin
	// InstallZplugin()
	// // for prezto
	// InstallPrezto()
	// // for powerlevel10k
	// InstallPowerlevel10k()
	// // for docker completion
	// InstallDockerCompletion()

	// // for TPM
	// // InstallTPM() // will be installed in the setup phase in each OS.

	// // for pyenv
	// InstallPyenv()
	// // for rbenv
	// InstallRbenv()

	// // for spacemacs
	// InstallSpacemacs()

}
