package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

// func makeDotfilesDirectory() {
// 	err := execute("Make directory", "mkdir", "-p", DotfilesDirectory)
// 	if err != nil {
// 		log.Fatal(err)
// 	}
// 	printResult(fmt.Sprintf("Create '%s'", DotfilesDirectory), err)
// }

// func extractDotfilesDirectory() {
// 	err = extract(tmpFile.Name(), DotfilesDirectory)
// 	printResult("Extract archive", err)
// }

func downloadDotfiles() {
	printInPurple("• Download and extract archive")

	tmpFile, err := ioutil.TempFile("/tmp/", "XXXXX")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())

	err = download(DotfilesTarballUrl, tmpFile.Name())
	printResult("Download archive\n", err)

	if !IsSkipQuestions {
		msg := fmt.Sprintf("Do you want to store the dotfiles in '%s'", DotfilesDirectory)
		answerIsYes := askForConfirmation(msg)
		if !answerIsYes {
			for {
				DotfilesDirectory = ""
				DotfilesDirectory = ask("Please specify another location for the dotfiles (path): ")
				if DotfilesDirectory != "" {
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
		// 			err := execute("Remove directory", "rm", "-rf", DotfilesDirectory)
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
		err := execute("Remove directory", "rm", "-rf", DotfilesDirectory)
		if err != nil {
			log.Fatal(err)
		}
	}

	err = execute("Make directory", "mkdir", "-p", DotfilesDirectory)
	if err != nil {
		log.Fatal(err)
	}
	printResult(fmt.Sprintf("Create '%s'", DotfilesDirectory), err)

	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	// Extract archive in the `dotfiles` directory.

	err = extract(tmpFile.Name(), DotfilesDirectory)
	printResult("Extract archive", err)

}
