package ztlib

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/stianeikeland/go-rpio"
	"go.bug.st/serial"
)

func ReceiveText(serialPort serial.Port, msgs <-chan bool, state ConfigState,
	logtexts chan string) {
	// This will be run asynchronously as a Go routine to print incoming
	// text as it arrives.
	recvBuf := make([]byte, RecvBufSize)
	loop := true
	for loop {
		select { // using select to make this non-blocking
		case msg := <-msgs:
			state.LogSession = msg
		default:
			// nothing for now - more is coming
		}
		n, readError := serialPort.Read(recvBuf)
		if readError != nil {
			fmt.Println(readError)
		} else if n > 0 {
			if state.Imode == "raw" {
				for i := 0; i < n; i++ {
					if recvBuf[i] == 10 {
						fmt.Println("\r")
					} else {
						fmt.Print(string(recvBuf[i]))
					}
				}
			} else {
				fmt.Print(string(recvBuf[:n]))
			}
			if state.LogSession {
				logtexts <- string(recvBuf[:n])
			}
		}
	}
}

func ResetZolatron(rPin rpio.Pin) {
	// Pull the reset line low. As we are using a MOSFET to control the line,
	// this means setting the control line (rPin) high.
	fmt.Println("\n*** Resetting Zolatron ***")
	rPin.Write(rpio.High)
	time.Sleep(time.Second)
	rPin.Write(rpio.Low)
}

func SendText(msg []byte, serialPort serial.Port, state ConfigState,
	logtexts chan string) {
	for _, chr := range msg {
		if chr == CR || chr == NEWLINE {
			// do nothing - just editing out these chars
		} else {
			serialPort.Write([]byte{chr})
			time.Sleep(CharDelay * time.Millisecond)
		}
	}
	serialPort.Write([]byte{NULL}) // Now send the line terminator
	if state.LogSession {
		logtexts <- string(msg) + "\n"
	}
}

func SetTestMsg(state ConfigState) {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("\nNew test message: ")
	input, _ := reader.ReadString('\n')
	state.TestMsg = strings.TrimSuffix(input, "\n")
	fmt.Println("New message is:", state.TestMsg)
	//zt.PrintPrompt(termState)
}
