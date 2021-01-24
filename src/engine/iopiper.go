package main

// This program is spawned as a sub process from the Godot UDP interface script
// It serves as pipe line between Godot and a running CLI process
// It pipes UDP packets to Stdio back and forth Godot - here - CLI App
// Also it executes and kills the sub processes (harsh)

import (
	"bufio"
	"io"
	"net"
	"os"
	"os/exec"
)

func main() {
	var clientAddr net.Addr

	// Expect an executable path as 2nd arg
	args := os.Args
	if len(args) < 2 {
		os.Exit(1)
	}

	// Set up UDP listner
	pc, err := net.ListenPacket("udp", ":7070")
	if err != nil {
		os.Exit(2)
	}
	defer pc.Close()

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
			if _, err := pc.WriteTo([]byte(s.Text()), clientAddr); err != nil {
				os.Exit(3)
			}
		}
	}()

	// Start the process
	proc.Start()

	buffer := make([]byte, 2048)
	for {
		_, addr, err := pc.ReadFrom(buffer)
		clientAddr = addr
		if err == nil {
			//rcvMsq := string(buffer)
			//io.WriteString(stdin, rcvMsq+"\n")
			io.WriteString(stdin, "TEST\na\nx\nv\n") // This simulates a problem with the buffer above. But maybe solved by:
			// Clear the bytes or add a delay
			// https://stackoverflow.com/questions/59939773/how-to-clear-a-bytes-buffer-that-is-set-as-stdout-in-exec-command-in-golang-b-r
		} else {
			os.Exit(4)
		}
	}
}
