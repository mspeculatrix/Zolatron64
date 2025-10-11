package zdlib

import (
	"fmt"
	"log"
	"strings"

	"github.com/stianeikeland/go-rpio"
)

// CheckClientOnlineState()
func CheckClientOnlineState(cloSig rpio.Pin, prevState rpio.State) (rpio.State, bool) {
	changed := false
	state := cloSig.Read()
	if state != prevState {
		changed = true
	}
	return state, changed
}

// LogMessage()
func LogMessage(verbose bool, msgs ...string) {
	message := strings.Join(msgs, " ")
	if verbose {
		//		for _, msg := range msgs {
		fmt.Println(message)
	}
	log.Println(message)
}

// PrintLine()
func PrintLine(verbose bool) {
	LogMessage(verbose, strings.Repeat("-", 50))
}

// ReadDataPortValue
func ReadDataPortValue(dport []rpio.Pin) int {
	val := 0
	for i := 0; i < 8; i++ {
		databit := dport[i].Read()
		if databit == rpio.High {
			val = val | (1 << i)
		}
	}
	return val
}

// SetDataPortDirection()
func SetDataPortDirection(dport []rpio.Pin, portdir int) {
	//zdlib.LogMessage("- setting data port to", dataDirs[portdir])
	for i := 0; i < 8; i++ {
		if portdir == DIR_INPUT {
			dport[i].Input()
		} else {
			dport[i].Output()
		}
	}
}

// SetDataPortValue()
func SetDataPortValue(dport []rpio.Pin, val int) {
	for i := 0; i < 8; i++ {
		bit := val & (1 << i)
		if bit == 0 {
			dport[i].Write(rpio.Low)
		} else {
			dport[i].Write(rpio.High)
		}
	}
}
