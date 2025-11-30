/*
	ZTerm
	A simple command line serial terminal intended to be used with the
	Zolatron 64 6502-based homebrew computer.

	https://mansfield-devine.com/speculatrix/category/projects/zolatron/

	NB: Logging is always on (for now).

	Usage:
	zterm [-a] [-l] [-f <logfile>]
		-a	append to existing log file. Otherwise, overwrite.
		-f	file to use for logging. If not specified, the default is used.
		-p  port to use - eg, ttyACM0
		-t  test message to send when using command '/t'

	Info on term package:
	https://stackoverflow.com/questions/15159118/read-a-character-from-standard-input-in-go-without-pressing-enter
	https://pkg.go.dev/golang.org/x/term@v0.8.0

*/

package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"math"
	"os"
	"strings"
	"time"
	zt "zterm/ztlib"

	"github.com/stianeikeland/go-rpio"
	"go.bug.st/serial"
	"golang.org/x/term"
)

var (
	recvMsgs = make(chan bool, 8)
	logtexts = make(chan string)
	// ASCII codes of characters to ignore when sending
	//ignoreChars = []byte{zt.NEWLINE, zt.CR}

	termState = zt.ConfigState{
		Imode:          "raw",   // or "cmd" - input mode
		ReturnMode:     zt.NULL, // or RTN - how <return> key is treated
		LogSession:     true,
		LogState:       "on",
		TestMsg:        "This is a test.",
		ConvertToUpper: 1, // convert alpha chars to uppercase in raw mode?
		ShowKeyCodes:   0,
	}

	config = zt.AppConfig{
		Version:  "1.1.0",
		ComPort:  "serial0", // serial1 ttyAMA0 ttyUSB0
		BaudRate: 9600,      // default. Good enough.
		LogFile:  zt.DefaultLogFile,
	}
)

// func isCharToIgnore(chr byte) bool {
// 	result := false
// 	for _, v := range ignoreChars {
// 		if chr == v {
// 			result = true
// 		}
// 	}
// 	return result
// }

func localCommand(cmd string, serialPort serial.Port) (bool, bool) {
	loop := true
	mainloop := true
	switch cmd {
	case "f", "F":
		fmt.Println("Log file:", config.LogFile)
		zt.PrintPrompt(termState)
	case "g", "G":
		if termState.LogSession {
			termState.LogSession = false
			termState.LogState = "off"
		} else {
			termState.LogSession = true
			termState.LogState = "on"
		}
		recvMsgs <- termState.LogSession
		fmt.Println("Logging: " + termState.LogState)
		zt.PrintPrompt(termState)
	case "h", "H":
		fmt.Printf("%sf  show log filename       %sg  start/stop logging\n", zt.CmdChar, zt.CmdChar)
		fmt.Printf("%sh  this help text          %sm  set test message\n", zt.CmdChar, zt.CmdChar)
		fmt.Printf("%sr  reset Zolatron          %ss  show settings\n", zt.CmdChar, zt.CmdChar)
		fmt.Printf("%st  send test message       %sw  raw mode\n", zt.CmdChar, zt.CmdChar)
		fmt.Printf("%sq  quit\n", zt.CmdChar)
		zt.PrintPrompt(termState)
	case "m", "M":
		zt.SetTestMsg(termState)
		zt.PrintPrompt(termState)
	case "r", "R":
		zt.ResetZolatron(zt.Reset)
	case "s", "S": // show settings
		zt.ShowStatus(termState, config)
	case "t", "T": // send test message
		fmt.Println(termState.TestMsg)
		zt.SendText([]byte(termState.TestMsg), serialPort, termState, logtexts)
	case "q", "Q":
		loop = false
		mainloop = false
	case "w", "W":
		loop = false
		termState.Imode = "raw"
		fmt.Println("-- Switched to RAW mode --")
		zt.ShowFkeys()
		zt.ShowReturnMode(termState)
		zt.PrintPrompt(termState)
	default:
		fmt.Println("Not a command")
		zt.PrintPrompt(termState)
	} // end switch
	return loop, mainloop
}

func logText(msgs <-chan string, logF *log.Logger) {
	loop := true
	logStr := ""
	for loop {
		msg := <-msgs
		for _, chr := range msg {
			if string(chr) == "\n" {
				logF.Print(logStr)
				logStr = ""
			} else {
				logStr = logStr + string(chr)
			}
		}
	}
}

/*******************************************************************************
 ***  MAIN                                                                   ***
 ******************************************************************************/
func main() {
	gpioErr := rpio.Open()
	if gpioErr != nil {
		log.Fatal("Could not open GPIO")
	}
	// command-line flags
	flag.BoolVar(&zt.Append, "a", zt.Append, "append to log file")
	flag.StringVar(&config.LogFile, "f", config.LogFile, "filename (with path)")
	//flag.BoolVar(&LogSession, "l", LogSession, "log session to file")
	flag.StringVar(&config.ComPort, "p", config.ComPort, "port")
	flag.StringVar(&termState.TestMsg, "t", termState.TestMsg, "test message")
	flag.Parse()

	zt.Reset.Output()
	zt.Reset.Write(rpio.Low)

	// configure serial
	mode := &serial.Mode{BaudRate: config.BaudRate}
	serialPort, err := serial.Open("/dev/"+config.ComPort, mode)
	if err != nil {
		log.Fatal("Problem opening serial port /dev/"+config.ComPort+" - ", err)
	}
	defer serialPort.Close()

	if config.LogFile == "" {
		config.LogFile = zt.DefaultLogFile
	} else {
		termState.LogSession = true
	}

	if zt.Append {
		zt.FileMode = os.O_APPEND | os.O_CREATE | os.O_WRONLY
		termState.LogSession = true
	}
	// We always open a log file, if only to record a date stamp.
	fh, err := os.OpenFile(config.LogFile, zt.FileMode, 0664)
	if err != nil {
		log.Fatalln("Problem opening log file:", err)
	}
	defer fh.Close()

	dt := time.Now()

	logger := log.New(fh, "", 0) // using a log object because atomic. No prefix
	logger.Println("Zolaterm session:", dt.Format("2006/01/02 15:04:05"))

	fmt.Printf("\n\nZolaTerm %-10s\n", config.Version)
	fmt.Printf("%s\n", strings.Repeat("-", 68))
	fmt.Printf("Console port : /dev/%-19s Input mode: %-15s\n", config.ComPort, strings.ToUpper(termState.Imode))
	fmt.Printf("Log filename : %-24s Logging is: %-15s \n", config.LogFile, termState.LogState)
	fmt.Printf("Local cmd key: %-24s %sh for help, %sw for RAW mode\n", zt.CmdChar, zt.CmdChar, zt.CmdChar)
	fmt.Println("")

	zt.ShowFkeys()
	zt.ShowReturnMode(termState)
	zt.ShowUpperMode(termState)
	zt.ShowKeycodesMode(termState)

	// start Go routines
	go zt.ReceiveText(serialPort, recvMsgs, termState, logtexts)
	go logText(logtexts, logger)

	// *************************************************************************
	// *****   MAIN LOOP                                                   *****
	// *************************************************************************

	mainloop := true

	// Send a line terminator in order to get a response, and a prompt, from
	// the Zolatron.
	serialPort.Write([]byte{zt.NULL})

	for mainloop {
		inputloop := true
		if termState.Imode == "raw" {
			/*******************************************************************
			*****  RAW INPUT MODE                                          *****
			*******************************************************************/
			for inputloop {
				ichar := make([]byte, 5)
				oldState, _ := term.MakeRaw(int(os.Stdin.Fd()))
				_, err := os.Stdin.Read(ichar)
				term.Restore(int(os.Stdin.Fd()), oldState)
				if termState.ShowKeyCodes == 1 {
					fmt.Print(ichar)
				}
				if err != nil {
					fmt.Println("Say again?", err)
				} else {
					/* ***** PROCESS INPUT ***** */
					// NB: Values of 1-26 for ichar[0] represent Ctrl-A..Ctrl-Z.
					// We're already testing for Ctrl-H (Backspace, ASCII 8)
					// and Ctrl-G (ASCII 7) is the bell, which is
					// probably best avoided. But the others are all available.
					switch ichar[0] {
					case zt.BS, zt.DEL: // Backspace or Delete
						// we'll always send zt.BS
						fmt.Printf("\b \b")
						serialPort.Write([]byte{zt.BS})
					case zt.CR: // Carriage return
						// If zt.RTN mode, just send what was actually typed.
						// Otherwise, send a zt.NULL character.
						fmt.Println("\r")
						if termState.ReturnMode == zt.RTN {
							// zt.RTN mode, so just send what was actually typed
							serialPort.Write([]byte{ichar[0]})
						} else {
							// zt.NULL mode - send zt.NULL character
							serialPort.Write([]byte{zt.NULL})
						}
					case zt.NEWLINE: // Linefeed
						// If zt.RTN mode, just send what was actually typed.
						// Otherwise, ignore.
						if termState.ReturnMode == zt.RTN {
							serialPort.Write([]byte{ichar[0]})
						}
					case zt.TAB: // Tab
						fmt.Print("<tab>")
						serialPort.Write([]byte{ichar[0]})
					case zt.ESCAPE: // escape char
						switch ichar[1] {
						case 0: // zt.ESCAPE key
							termState.Imode = "cmd"
							inputloop = false
							fmt.Println("\n-- Switched to CMD mode --")
							zt.PrintPrompt(termState)
						case 79: // F-keys - f1-f4
							switch ichar[2] {
							case 80: // F1 - show status
								fmt.Println("")
								zt.ShowStatus(termState, config)
							case 81: // F2 - toggle return mode
								if termState.ReturnMode == zt.NULL {
									termState.ReturnMode = zt.RTN
								} else {
									termState.ReturnMode = zt.NULL
								}
								zt.ShowReturnMode(termState)
								zt.PrintPrompt(termState)
							case 82: // F3 - send test message
								fmt.Println(termState.TestMsg)
								serialPort.Write([]byte(termState.TestMsg))
								serialPort.Write([]byte{zt.NULL})
							case 83: // F4 - send a zt.NULL byte
								serialPort.Write([]byte{zt.NULL})
								fmt.Println("")
							}
						case 91: // func & arrow keys
							switch ichar[2] {
							case 49: // F5-F8
								switch ichar[3] {
								case 53: // F5
									zt.SetTestMsg(termState)
									zt.PrintPrompt(termState)
								case 55: // F6
									termState.ShowKeyCodes = int(math.Abs(float64(termState.ShowKeyCodes) - 1))
									fmt.Println("Keycodes", zt.ToggleStates[termState.ShowKeyCodes])
									zt.PrintPrompt(termState)
								case 56: // F7
									fmt.Println("F7")
									zt.PrintPrompt(termState)
								case 57: // F8
									zt.ResetZolatron(zt.Reset)
								}
							case 50: // F9 & F10
								switch ichar[3] {
								case 48: // F9
									termState.ConvertToUpper = int(math.Abs(float64(termState.ConvertToUpper) - 1))
									zt.ShowUpperMode(termState)
									zt.PrintPrompt(termState)
								case 49: // F10
									inputloop = false
									mainloop = false
								} // switch ichar[3]
							case 53: // page up
								fmt.Println("pgup")
								zt.PrintPrompt(termState)
							case 54: // page down
								fmt.Println("pgdn")
								zt.PrintPrompt(termState)
							case 65: // up
								fmt.Println("up")
								zt.PrintPrompt(termState)
							case 66: // down
								fmt.Println("dn")
								zt.PrintPrompt(termState)
							case 67: // right
								fmt.Println("rt")
								zt.PrintPrompt(termState)
							case 68: // left
								fmt.Println("lt")
								zt.PrintPrompt(termState)
							case 70: // end
								fmt.Println("end")
								zt.PrintPrompt(termState)
							case 72: // home
								fmt.Println("home")
								zt.PrintPrompt(termState)
							default:
								fmt.Println(ichar)
								zt.PrintPrompt(termState)
							} // switch ichar[2]
						default:
							fmt.Println(ichar)
							zt.PrintPrompt(termState)
						} // switch ichar[1]
					default:
						if (ichar[0] > 96 && ichar[0] < 123) && termState.ConvertToUpper == 1 {
							ichar[0] = ichar[0] - 32
						}
						fmt.Print(string(ichar[0]))
						serialPort.Write([]byte{ichar[0]})
					} // switch ichar[0]
				} // no error
			}
		} else {
			/*******************************************************************
			*****  CMD INPUT MODE                                          *****
			*******************************************************************/
			reader := bufio.NewReader(os.Stdin)
			for inputloop {
				inputStr := ""
				input, err := reader.ReadBytes(zt.LINETERM) // read keyboard. Blocking.
				// fmt.Println(input)
				inputStr = strings.TrimSpace(string(input))
				inputStr = strings.ToUpper(inputStr)
				if err != nil {
					fmt.Println("Say again?", err)
				} else {
					if len(inputStr) > 0 && inputStr[0:1] == zt.CmdChar {
						// LOCAL COMMANDS
						cmd := inputStr[1:]
						if len(cmd) > 0 {
							inputloop, mainloop = localCommand(cmd, serialPort)
						}
					} else {
						// COMMAND TO SEND
						input := []byte(inputStr)
						zt.SendText(input, serialPort, termState, logtexts)
					}
				}
			} // inputloop
		}
	} // mainloop

	fmt.Println("\nBye!")

}
