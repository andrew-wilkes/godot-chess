package main

// This application listens for incoming UDP packets and sends back an acknowledgement to where they came from

import (
	"fmt"
	"log"
	"net"
	"strings"
)

func main() {
	pc, err := net.ListenPacket("udp", ":7070")
	if err != nil {
		log.Fatal(err)
	}
	defer pc.Close()

	buffer := make([]byte, 128)
	fmt.Println("Waiting for client...")
	for {
		_, addr, err := pc.ReadFrom(buffer)
		if err == nil {
			rcvMsq := string(buffer)
			fmt.Println("Received: " + rcvMsq)
			// The following code was later simplified to: io.WriteString(stdin, fmt.Sprintf("%s\n", buffer[:n])) in iopiper.go
			if _, err := pc.WriteTo([]byte(strings.Split(rcvMsq, "\n")[0]+"\n"), addr); err != nil {
				fmt.Println("error on write: " + err.Error())
			}
		} else {
			fmt.Println("error: " + err.Error())
		}
	}
}
