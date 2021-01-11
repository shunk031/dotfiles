package util

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"testing"
)

func askWrapper(content []byte) string {
	tmpFile, err := ioutil.TempFile("/tmp", "test_ask")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.Write(content); err != nil {
		log.Fatal(err)
	}

	if _, err := tmpFile.Seek(0, 0); err != nil {
		log.Fatal(err)
	}

	oldStdin := os.Stdin
	defer func() { os.Stdin = oldStdin }() // Restore original Stdin

	os.Stdin = tmpFile
	response := ask("Test ask")

	if err := tmpFile.Close(); err != nil {
		log.Fatal(err)
	}

	return response
}

func TestAsk(t *testing.T) {
	testStdIn := "test_ask_dir"
	response := askWrapper([]byte(fmt.Sprintf("%s\n", testStdIn)))
	if response != testStdIn {
		t.Fatal("Test failed")
	}

	testStdIn = "test_ask_filepath"
	response = askWrapper([]byte(fmt.Sprintf("%s\n", testStdIn)))
	if response != testStdIn {
		t.Fatal("Test failed")
	}
}

func askForConfirmationWrapper(content []byte) bool {
	tmpFile, err := ioutil.TempFile("/tmp", "test_ask_for_confirmation")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.Write(content); err != nil {
		log.Fatal(err)
	}

	if _, err := tmpFile.Seek(0, 0); err != nil {
		log.Fatal(err)
	}

	oldStdin := os.Stdin
	defer func() { os.Stdin = oldStdin }() // Restore original Stdin

	os.Stdin = tmpFile

	answer := askForConfirmation("Test for askForConfirmation")

	if err := tmpFile.Close(); err != nil {
		log.Fatal(err)
	}

	return answer
}

func TestAskForConfirmationYes(t *testing.T) {
	answer := askForConfirmationWrapper([]byte("y\n"))
	if !answer {
		t.Fatal("Test failed")
	}

	answer = askForConfirmationWrapper([]byte("yes\n"))
	if !answer {
		t.Fatal("Test failed")
	}
}

func TestAskForConfirmationNo(t *testing.T) {
	answer := askForConfirmationWrapper([]byte("n\n"))
	if answer {
		t.Fatal("Test failed")
	}

	answer = askForConfirmationWrapper([]byte("no\n"))
	if answer {
		t.Fatal("Test failed")
	}
}
