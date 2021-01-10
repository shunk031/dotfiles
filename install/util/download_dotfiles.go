package util

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

// func makeDotfilesDirectory() {
// 	err := Execute("Make directory", "mkdir", "-p", DotfilesDirectory)
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	printResult(fmt.Sprintf("Create '%s'", DotfilesDirectory), err)
// }

// func extractDotfilesDirectory() {
// 	err = extract(tmpFile.Name(), DotfilesDirectory)
// 	printResult("Extract archive", err)
// }

func download(url string, output string) error {
	msg := fmt.Sprintf("Download from %s to %s", url, output)

	var err error
	if CmdExists("curl") {
		err = Execute(msg, "curl", "-LsSo", output, url)
		//                            │││└─ write output to file
		//                            ││└─ show error messages
		//                            │└─ don't show the progress meter
		//                            └─ follow redirects
	} else if CmdExists("wget") {
		err = Execute(msg, "wget", "-qO", output, url)
		//                            │└─ write output to file
		//                            └─ don't show output
	}
	return err
}

func DownloadDotfiles(dotfilesDir string, tarballUrl string, isSkipQuestions bool) {
	printInPurple("• Download and extract archive")

	tmpFile, err := ioutil.TempFile("/tmp/", "XXXXX")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())
	defer printResult("Remove archive", nil)

	err = download(tarballUrl, tmpFile.Name())
	printResult("Download archive\n", err)

	if !isSkipQuestions {
		msg := fmt.Sprintf("Do you want to store the dotfiles in '%s'", dotfilesDir)
		answerIsYes := askForConfirmation(msg)
		if !answerIsYes {
			for {
				dotfilesDir = ""
				dotfilesDir = ask("Please specify another location for the dotfiles (path): ")
				if dotfilesDir != "" {
					break
				}
			}
		}

		// Ensure the `dotfiles` directory is available
		// for {
		// 	if _, err := os.Stat(DotfilesDirectory); os.IsExist(err) {
		// 		msg := fmt.Sprintf("'%s' already exists, do you want to overwrite it?", DotfilesDirectory)
		// 		answerIsYes := askForConfirmation(msg)
		// 		if answerIsYes {
		// 			err := Execute("Remove directory", "rm", "-rf", DotfilesDirectory)
		// 			if err != nil {
		// 				log.Fatal(err)
		// 			}
		// 			break
		// 		} else {
		// 			DotfilesDirectory = ""
		// 			DotfilesDirectory = ask("Please specify another location for the dotfiles (path): ")
		// 			if DotfilesDirectory != "" {
		// 				break
		// 			}
		// 		}
		// 	}
		// }
	} else {
		err := Execute("Remove directory", "rm", "-rf", dotfilesDir)
		if err != nil {
			log.Fatal(err)
		}
	}

	err = Execute("Make directory", "mkdir", "-p", dotfilesDir)
	if err != nil {
		log.Fatal(err)
	}
	printResult(fmt.Sprintf("Create '%s'", dotfilesDir), err)

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Extract archive in the `dotfiles` directory.

	err = extract(tmpFile.Name(), dotfilesDir)
	printResult("Extract archive", err)

	if err := tmpFile.Close(); err != nil {
		log.Fatal(err)
	}
}
