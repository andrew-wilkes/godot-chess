package main

// This application listens for incoming UDP packets and sends back an acknowledgement to where they came from

import (
	"fmt"
	"log"
	"net"
)

func main() {
	pc, err := net.ListenPacket("udp", ":7070")
	if err != nil {
		log.Fatal(err)
	}
	defer pc.Close()

	buffer := make([]byte, 2048)
	fmt.Println("Waiting for client...")
	for {
		_, addr, err := pc.ReadFrom(buffer)
		if err == nil {
			rcvMsq := string(buffer)
			fmt.Println("Received: " + rcvMsq)
			if _, err := pc.WriteTo([]byte("Ack: "+rcvMsq), addr); err != nil {
				fmt.Println("error on write: " + err.Error())
			}
		} else {
			fmt.Println("error: " + err.Error())
		}
	}
}
