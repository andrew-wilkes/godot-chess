package main

// This program simply echos what is typed into the command line

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	sc := bufio.NewScanner(os.Stdin)

	// sc.Scan() blocks until a new line of text is entered
	for sc.Scan() {
		// Print the captured line of text
		fmt.Println(sc.Text())
	}
}
