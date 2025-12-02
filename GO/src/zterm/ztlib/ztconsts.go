package ztlib

import (
	"os"

	"github.com/stianeikeland/go-rpio"
)

const (
	CmdChar             = "/"  // prefix for local commands
	RecvBufSize         = 1024 // recieve buffer size, in bytes
	CharDelay           = 10   // ms between characters
	NULL           byte = 0    // NULL mode for return key
	RTN            byte = 1    // Indicates RTN mode for return key
	BS             byte = 8    // Backspace
	TAB            byte = 9    // Tab
	LINETERM       byte = 10   // ASCII char to use as line terminator
	NEWLINE        byte = 10   // Linefeed
	DEL            byte = 127  // Delete
	CR             byte = 13   // Carriage return
	ESCAPE         byte = 27
	DefaultLogFile      = "zterm.log"
)

var (
	ToggleStates      = []string{"OFF", "ON"}
	FileMode          = os.O_CREATE | os.O_TRUNC | os.O_WRONLY
	Reset             = rpio.Pin(21)
	Append       bool = false
)
