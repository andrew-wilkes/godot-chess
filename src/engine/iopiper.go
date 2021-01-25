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
	"strings"
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
			txt := s.Text()
			if _, err := pc.WriteTo([]byte(txt), clientAddr); err != nil {
				os.Exit(3)
			}
		}
	}()

	// Start the process
	proc.Start()

	buffer := make([]byte, 256)
	for {
		_, addr, err := pc.ReadFrom(buffer)
		clientAddr = addr
		if err == nil {
			rcvMsq := string(buffer)
			// Only write the first line of the buffer (not the whole buffer)
			io.WriteString(stdin, strings.Split(rcvMsq, "\n")[0]+"\n")
		} else {
			os.Exit(4)
		}
	}
}
