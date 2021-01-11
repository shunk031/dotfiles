package util

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

func ask(msg string) string {
	printQuestion(msg)

	reader := bufio.NewReader(os.Stdin)
	response, err := reader.ReadString('\n')
	if err != nil {
		log.Fatal(err)
	}
	response = strings.TrimSpace(response)

	fmt.Println()
	return response
}

func askForConfirmation(msg string) bool {
	printQuestion(fmt.Sprintf("%s (y/n) ", msg))

	reader := bufio.NewReader(os.Stdin)
	for {
		response, err := reader.ReadString('\n')
		if err != nil {
			log.Fatal(err)
		}

		response = strings.ToLower(strings.TrimSpace(response))

		if response == "y" || response == "yes" {
			// fmt.Println()
			return true
		} else if response == "n" || response == "no" {
			// fmt.Println()
			return false
		}
	}
}
