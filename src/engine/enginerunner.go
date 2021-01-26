package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"time"
)

func main() {
	// Expect an executable path as 2nd arg
	args := os.Args
	if len(args) < 2 {
		fmt.Println("Missing executable path parameter")
		os.Exit(1)
	}

	// Set up external process
	proc := exec.Command(args[1])

	// The process input is obtained
	// in form of io.WriteCloser. The underlying
	// implementation uses the os.Pipe
	stdin, _ := proc.StdinPipe()
	defer stdin.Close()

	// Watch the output of the executed process
	stdout, _ := proc.StdoutPipe()
	defer stdout.Close()

	// Run stdout scanner in a thread
	go func() {
		s := bufio.NewScanner(stdout)
		for s.Scan() {
			fmt.Println(s.Text())
		}
	}()

	// Start the process
	proc.Start()
	time.Sleep(100 * time.Millisecond)
	io.WriteString(stdin, "uci\n")
	time.Sleep(5 * time.Second)
	io.WriteString(stdin, "quit\n")
	time.Sleep(1 * time.Second)
}
