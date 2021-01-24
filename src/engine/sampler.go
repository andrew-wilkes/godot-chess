package main

// This program simply echos what is typed into the command line
// But it is used in testing as a dummy chess engine where iopiper activates it,
// sends it lines of input and reads it's output via Stdio

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	sc := bufio.NewScanner(os.Stdin)

	// sc.Scan() blocks until a new line of text is entered
	for sc.Scan() {
		// Print the captured line of text to Stdout
		fmt.Println(sc.Text())
	}
}
