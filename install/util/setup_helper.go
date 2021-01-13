package util

import "fmt"

type Helper struct {
	Name string
}

func (h Helper) Print() {
	PrintInPurple(fmt.Sprintf("\n  For %s\n", h.Name))
}
