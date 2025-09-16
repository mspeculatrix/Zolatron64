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

	"github.com/stianeikeland/go-rpio"
	"go.bug.st/serial"
	"golang.org/x/term"
)

const (
	version             = "1.0.1"
	cmdChar             = "/"  // prefix for local commands
	recvBufSize         = 1024 // recieve buffer size, in bytes
	charDelay           = 10   // ms between characters
	NULL           byte = 0    // NULL mode for return key
	RTN            byte = 1    // Indicates RTN mode for return key
	BS             byte = 8    // Backspace
	TAB            byte = 9    // Tab
	LINETERM       byte = 10   // ASCII char to use as line terminator
	NEWLINE        byte = 10   // Linefeed
	DEL            byte = 127  // Delete
	CR             byte = 13   // Carriage return
	ESCAPE         byte = 27
	defaultLogFile      = "zterm.log"
)

var (
	comPort    = "serial0" // serial1 ttyAMA0 ttyUSB0
	baudRate   = 9600      // default
	logFile    = defaultLogFile
	fileMode   = os.O_CREATE | os.O_TRUNC | os.O_WRONLY
	append     = false
	imode      = "raw" // or "cmd" - input mode
	returnMode = NULL  // or RTN - how <return> key is treated
	// recvMsgs    = make(chan []byte, recvBufSize)
	// logtexts    = make(chan []byte, recvBufSize)
	logSession = true
	logState   = "on"
	recvMsgs   = make(chan bool, 8)
	logtexts   = make(chan string)
	// ASCII codes of characters to ignore when sending
	//ignoreChars = []byte{NEWLINE, CR}
	testMsg            = "This is a test."
	reset              = rpio.Pin(21)
	convertToUpper     = 1 // convert alpha chars to uppercase in raw mode?
	toggleStates       = []string{"OFF", "ON"}
	showKeyCodes   int = 0
)

func printPrompt() {
	if convertToUpper == 1 {
		fmt.Print("Z>")
	} else {
		fmt.Print("z>")
	}
}

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
		fmt.Println("Log file:", logFile)
		printPrompt()
	case "g", "G":
		if logSession {
			logSession = false
			logState = "off"
		} else {
			logSession = true
			logState = "on"
		}
		recvMsgs <- logSession
		fmt.Println("Logging: " + logState)
		printPrompt()
	case "h", "H":
		fmt.Printf("%sf  show log filename       %sg  start/stop logging\n", cmdChar, cmdChar)
		fmt.Printf("%sh  this help text          %sm  set test message\n", cmdChar, cmdChar)
		fmt.Printf("%sr  reset Zolatron          %ss  show settings\n", cmdChar, cmdChar)
		fmt.Printf("%st  send test message       %sw  raw mode\n", cmdChar, cmdChar)
		fmt.Printf("%sq  quit\n", cmdChar)
		printPrompt()
	case "m", "M":
		setTestMsg()
		printPrompt()
	case "r", "R":
		resetZolatron(reset)
	case "s", "S": // show settings
		showStatus()
	case "t", "T": // send test message
		fmt.Println(testMsg)
		sendText([]byte(testMsg), serialPort)
	case "q", "Q":
		loop = false
		mainloop = false
	case "w", "W":
		loop = false
		imode = "raw"
		fmt.Println("-- Switched to RAW mode --")
		showFkeys()
		showReturnMode()
		printPrompt()
	default:
		fmt.Println("Not a command")
		printPrompt()
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

func receiveText(serialPort serial.Port, msgs <-chan bool, logS bool) {
	// This will be run asynchronously as a Go routine to print incoming
	// text as it arrives.
	recvBuf := make([]byte, recvBufSize)
	loop := true
	for loop {
		select { // using select to make this non-blocking
		case msg := <-msgs:
			logS = msg
		default:
			// nothing for now - more is coming
		}
		n, readError := serialPort.Read(recvBuf)
		if readError != nil {
			fmt.Println(readError)
		} else if n > 0 {
			if imode == "raw" {
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
			if logS {
				logtexts <- string(recvBuf[:n])
			}
		}
	}
}

func resetZolatron(rPin rpio.Pin) {
	// Pull the reset line low. As we are using a MOSFET to control the line,
	// this means setting the control line (rPin) high.
	fmt.Println("\n*** Resetting Zolatron ***")
	rPin.Write(rpio.High)
	time.Sleep(time.Second)
	rPin.Write(rpio.Low)
}

func returnModeStr() (modeStr string) {
	modeStr = "RTN"
	if returnMode == NULL {
		modeStr = "NULL"
	}
	return modeStr
}

func setTestMsg() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("\nNew test message: ")
	input, _ := reader.ReadString('\n')
	testMsg = strings.TrimSuffix(input, "\n")
	fmt.Println("New message is:", testMsg)
	//printPrompt()
}

func showFkeys() {
	fmt.Println("<esc> switch to CMD mode")
	fmt.Println("F1    show status            F2    toggle NULL/RTN mode for <return>")
	fmt.Println("F3    send test message      F4    send NULL")
	fmt.Println("F5    set test message       F6    toggle keycodes")
	fmt.Println("                             F8    reset Zolatron")
	fmt.Println("F9    toggle uppercase       F10   quit")
}

func showReturnMode() {
	fmt.Println("\n-- Using", returnModeStr(), "mode for <return> key --")
}

func showUpperMode() {
	fmt.Println("\n-- Conversion to UPPERCASE is", toggleStates[convertToUpper], " --")
}

func showKeycodesMode() {
	fmt.Println("\n-- Show keycodes is", toggleStates[showKeyCodes], " --")
}

func showStatus() {
	fmt.Printf("Version   : %-15s  Log file    : %s\n", version, logFile)
	fmt.Printf("Port      : %-15s  Input mode  : %s\n", comPort, strings.ToUpper(imode))
	fmt.Printf("Baud rate : %-15d  Return mode : %s\n", baudRate, returnModeStr())
	fmt.Printf("Uppercase : %-15s  Test msg    : %s\n", toggleStates[convertToUpper], testMsg)
	if imode == "raw" {
		fmt.Println("Function keys:")
		showFkeys()
	}
	printPrompt()
}

func sendText(msg []byte, serialPort serial.Port) {
	for _, chr := range msg {
		if chr == CR || chr == NEWLINE {
			// do nothing - just editing out these chars
		} else {
			serialPort.Write([]byte{chr})
			time.Sleep(charDelay * time.Millisecond)
		}
	}
	serialPort.Write([]byte{NULL}) // Now send the line terminator
	if logSession {
		logtexts <- string(msg) + "\n"
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
	flag.BoolVar(&append, "a", append, "append to log file")
	flag.StringVar(&logFile, "f", logFile, "filename (with path)")
	//flag.BoolVar(&logSession, "l", logSession, "log session to file")
	flag.StringVar(&comPort, "p", comPort, "port")
	flag.StringVar(&testMsg, "t", testMsg, "test message")
	flag.Parse()

	reset.Output()
	reset.Write(rpio.Low)

	// configure serial
	mode := &serial.Mode{BaudRate: baudRate}
	serialPort, err := serial.Open("/dev/"+comPort, mode)
	if err != nil {
		log.Fatal("Problem opening serial port /dev/"+comPort+" - ", err)
	}
	defer serialPort.Close()

	if logFile == "" {
		logFile = defaultLogFile
	} else {
		logSession = true
	}

	if append {
		fileMode = os.O_APPEND | os.O_CREATE | os.O_WRONLY
		logSession = true
	}
	// We always open a log file, if only to record a date stamp.
	fh, err := os.OpenFile(logFile, fileMode, 0664)
	if err != nil {
		log.Fatalln("Problem opening log file:", err)
	}
	defer fh.Close()

	dt := time.Now()

	logger := log.New(fh, "", 0) // using a log object because atomic. No prefix
	logger.Println("Zolaterm session:", dt.Format("2006/01/02 15:04:05"))

	fmt.Printf("\n\nZolaTerm %-10s\n", version)
	fmt.Printf("%s\n", strings.Repeat("-", 68))
	fmt.Printf("Console port : /dev/%-19s Input mode: %-15s\n", comPort, strings.ToUpper(imode))
	fmt.Printf("Log filename : %-24s Logging is: %-15s \n", logFile, logState)
	fmt.Printf("Local cmd key: %-24s %sh for help, %sw for RAW mode\n", cmdChar, cmdChar, cmdChar)
	fmt.Println("")

	showFkeys()
	showReturnMode()
	showUpperMode()
	showKeycodesMode()

	// start Go routines
	go receiveText(serialPort, recvMsgs, logSession)
	go logText(logtexts, logger)

	// *************************************************************************
	// *****   MAIN LOOP                                                   *****
	// *************************************************************************

	mainloop := true

	// Send a line terminator in order to get a response, and a prompt, from
	// the Zolatron.
	serialPort.Write([]byte{NULL})

	for mainloop {
		inputloop := true
		if imode == "raw" {
			/*******************************************************************
			*****  RAW INPUT MODE                                          *****
			*******************************************************************/
			for inputloop {
				ichar := make([]byte, 5)
				oldState, _ := term.MakeRaw(int(os.Stdin.Fd()))
				_, err := os.Stdin.Read(ichar)
				term.Restore(int(os.Stdin.Fd()), oldState)
				if showKeyCodes == 1 {
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
					case BS, DEL: // Backspace or Delete
						// we'll always send BS
						fmt.Printf("\b \b")
						serialPort.Write([]byte{BS})
					case CR: // Carriage return
						// If RTN mode, just send what was actually typed.
						// Otherwise, send a NULL character.
						fmt.Println("\r")
						if returnMode == RTN {
							// RTN mode, so just send what was actually typed
							serialPort.Write([]byte{ichar[0]})
						} else {
							// NULL mode - send NULL character
							serialPort.Write([]byte{NULL})
						}
					case NEWLINE: // Linefeed
						// If RTN mode, just send what was actually typed.
						// Otherwise, ignore.
						if returnMode == RTN {
							serialPort.Write([]byte{ichar[0]})
						}
					case TAB: // Tab
						fmt.Print("<tab>")
						serialPort.Write([]byte{ichar[0]})
					case ESCAPE: // escape char
						switch ichar[1] {
						case 0: // ESCAPE key
							imode = "cmd"
							inputloop = false
							fmt.Println("\n-- Switched to CMD mode --")
							printPrompt()
						case 79: // F-keys - f1-f4
							switch ichar[2] {
							case 80: // F1 - show status
								fmt.Println("")
								showStatus()
							case 81: // F2 - toggle return mode
								if returnMode == NULL {
									returnMode = RTN
								} else {
									returnMode = NULL
								}
								showReturnMode()
								printPrompt()
							case 82: // F3 - send test message
								fmt.Println(testMsg)
								serialPort.Write([]byte(testMsg))
								serialPort.Write([]byte{NULL})
							case 83: // F4 - send a NULL byte
								serialPort.Write([]byte{NULL})
								fmt.Println("")
							}
						case 91: // func & arrow keys
							switch ichar[2] {
							case 49: // F5-F8
								switch ichar[3] {
								case 53: // F5
									setTestMsg()
									printPrompt()
								case 55: // F6
									showKeyCodes = int(math.Abs(float64(showKeyCodes) - 1))
									fmt.Println("Keycodes", toggleStates[showKeyCodes])
									printPrompt()
								case 56: // F7
									fmt.Println("F7")
									printPrompt()
								case 57: // F8
									resetZolatron(reset)
								}
							case 50: // F9 & F10
								switch ichar[3] {
								case 48: // F9
									convertToUpper = int(math.Abs(float64(convertToUpper) - 1))
									showUpperMode()
									printPrompt()
								case 49: // F10
									inputloop = false
									mainloop = false
								} // switch ichar[3]
							case 53: // page up
								fmt.Println("pgup")
								printPrompt()
							case 54: // page down
								fmt.Println("pgdn")
								printPrompt()
							case 65: // up
								fmt.Println("up")
								printPrompt()
							case 66: // down
								fmt.Println("dn")
								printPrompt()
							case 67: // right
								fmt.Println("rt")
								printPrompt()
							case 68: // left
								fmt.Println("lt")
								printPrompt()
							case 70: // end
								fmt.Println("end")
								printPrompt()
							case 72: // home
								fmt.Println("home")
								printPrompt()
							default:
								fmt.Println(ichar)
								printPrompt()
							} // switch ichar[2]
						default:
							fmt.Println(ichar)
							printPrompt()
						} // switch ichar[1]
					default:
						if (ichar[0] > 96 && ichar[0] < 123) && convertToUpper == 1 {
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
				input, err := reader.ReadBytes(LINETERM) // read keyboard. Blocking.
				// fmt.Println(input)
				inputStr = strings.TrimSpace(string(input))
				inputStr = strings.ToUpper(inputStr)
				if err != nil {
					fmt.Println("Say again?", err)
				} else {
					if len(inputStr) > 0 && inputStr[0:1] == cmdChar {
						// LOCAL COMMANDS
						cmd := inputStr[1:]
						if len(cmd) > 0 {
							inputloop, mainloop = localCommand(cmd, serialPort)
						}
					} else {
						// COMMAND TO SEND
						input := []byte(inputStr)
						sendText(input, serialPort)
					}
				}
			} // inputloop
		}
	} // mainloop

	fmt.Println("\nBye!")

}
