package util

import (
	"fmt"

	"github.com/logrusorgru/aurora"
)

func PrintInPurple(s string) {
	printInPurple(s)
}

func printInPurple(s string) {
	fmt.Println(aurora.Magenta(s))
}

func printInGreen(s string) {
	fmt.Print(aurora.Green(s))
}

func printInYellow(s string) {
	fmt.Print(aurora.Yellow(s))
}

func printInRed(s string) {
	fmt.Print(aurora.Red(s))
}

func printQuestion(s string) {
	printInYellow(fmt.Sprintf("  [?] %s", s))
}

func printSuccess(s string) {
	printInGreen(fmt.Sprintf("  [✔] %s\n", s))
}

func printWarning(s string) {
	printInYellow(fmt.Sprintf("  [!] %s\n", s))
}

func printError(s string, e error) {
	printInRed(fmt.Sprintf("  [✖] %s %s\n", s, e))
}

func printResult(s string, err error) {
	if err != nil {
		printError(s, err)
	} else {
		printSuccess(s)
	}
}

func PrintResult(s string, err error) {
	printResult(s, err)
}

func PrintSuccess(s string) {
	printSuccess(s)
}
