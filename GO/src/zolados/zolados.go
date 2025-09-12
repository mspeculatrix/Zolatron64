// Zolados
// Implements Z64 commands:
//   - LOAD
//   - LS
//   - SAVE

// NB: Don't seem to be using the interrupt connection yet, so interrupt
// checks in the Zolatron code have been disabled. Re-enable if interrupts
// wanted.

package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"zolados/zdlib"

	"github.com/stianeikeland/go-rpio"
)

const (
	version = "1.2"
)

var (
	logFile     = "/home/zd/zd.log"
	fileDir     = "/home/zd/zd_files"
	fileName    = "ZD"
	clActSig    = rpio.Pin(5)  // PB0
	clRdySig    = rpio.Pin(6)  // PB1
	clOnlineSig = rpio.Pin(12) // PB3
	svrRdySig   = rpio.Pin(19) // PB4
	svrActSig   = rpio.Pin(16) // PB5
	d0          = rpio.Pin(4)  // PA0..PA7
	d1          = rpio.Pin(17)
	d2          = rpio.Pin(18)
	d3          = rpio.Pin(27)
	d4          = rpio.Pin(22)
	d5          = rpio.Pin(23)
	d6          = rpio.Pin(24)
	d7          = rpio.Pin(25)
	dataPort    = []rpio.Pin{d0, d1, d2, d3, d4, d5, d6, d7}
	irq         = rpio.Pin(7)  // Active high
	intsel      = rpio.Pin(20) // Active high
	led         = rpio.Pin(8)  // Active high
	//dataDirs    = []string{"INPUT", "OUTPUT"}
	verbose     = false
	startTime   time.Time
	elapsedTime time.Duration
)

func clearInterrupt() {
	irq.Write(rpio.Low)    // Make inactive, just to be sure
	intsel.Write(rpio.Low) // Make inactive
}

// func setInterrupt() {
// 	intsel.Write(rpio.High)
// 	irq.Write(rpio.High)
// 	time.Sleep(zdlib.IrqDelay)
// 	irq.Write(rpio.Low)
// }

// SetLED()
func setLED(led_state rpio.State) {
	led.Write(led_state)
}

func waitForState(signal rpio.Pin, state rpio.State) int {
	result := zdlib.RescodeErr
	t := time.Now()
	loop := true
	for loop {
		sigState := signal.Read()
		if sigState == state {
			result = zdlib.RescodeMatchState
			loop = false
		} else if time.Since(t) >= zdlib.TimeoutDelay {
			result = zdlib.RescodeTimeout
			loop = false
		}
	}
	return result
}

func getString() (string, bool, string) {
	gStr := ""
	errFlag := false
	errStr := ""
	resperr := waitForState(clActSig, zdlib.ACTIVE) // Wait for CA low
	if resperr == zdlib.RescodeTimeout {
		errFlag = true
		errStr = "TO waiting for CA in getString() setup"
	} else {
		strloop := true
		for strloop {
			resperr = waitForState(clRdySig, zdlib.ACTIVE)
			if resperr == zdlib.RescodeTimeout {
				errFlag = true
				errStr = "TO waiting for CR in getString() loop"
			} else {
				chrcode := zdlib.ReadDataPortValue(dataPort)
				if (chrcode > 64 && chrcode < 91) || // 'A'-'Z'
					(chrcode == 46) || // '.'
					(chrcode > 47 && chrcode < 58) { // '0'-'9'
					gStr += string(rune(chrcode))
					gStr = strings.TrimSpace(gStr)
				}
				serverReadyStrobe(zdlib.DIR_INPUT)
				time.Sleep(zdlib.StringReadDelay)
				caState := clActSig.Read()
				if caState == rpio.High {
					strloop = false
				}
			}
		}
	}
	return gStr, errFlag, errStr
}

func processDone(bytesCounted int, resStr string) {
	elapsedTimeStr := ""
	bpsStr := ""
	if bytesCounted > 0 {
		elapsedTimeStr = fmt.Sprintf("- %.3gs", elapsedTime.Seconds())
		bpsStr = fmt.Sprintf("- %.1fB/s", float64(bytesCounted)/elapsedTime.Seconds())
	}
	zdlib.LogMessage(verbose, "- Done:", resStr, "-", strconv.Itoa(bytesCounted), "bytes", elapsedTimeStr, bpsStr)
}

func sendByte(byteVal int) (int, string) {
	zdlib.SetDataPortValue(dataPort, byteVal)
	sendErr := 0
	resultStr := ""
	serverReadyStrobe(zdlib.DIR_OUTPUT)
	resp1 := waitForState(clRdySig, zdlib.ACTIVE)
	if resp1 == zdlib.RescodeTimeout {
		sendErr = resp1
		resultStr = "TO waiting for CR to be active in sendbyte"
	} else {
		resp2 := waitForState(clRdySig, zdlib.NOT_ACTIVE)
		if resp2 == zdlib.RescodeTimeout {
			sendErr = resp2
			resultStr = "TO waiting for CR to be inactive in sendbyte"
		}
	}
	return sendErr, resultStr
}

func sendResponseCode(code int, respdelay time.Duration) (int, string) {
	zdlib.LogMessage(verbose, "- Sending response code:", fmt.Sprint(code))
	resultStr := "OK"
	resperr := waitForState(clActSig, zdlib.NOT_ACTIVE)
	if resperr == zdlib.RescodeMatchState {
		zdlib.SetDataPortDirection(dataPort, zdlib.DIR_OUTPUT)
		svrActSig.Write(zdlib.ACTIVE)
		resperr = waitForState(clRdySig, zdlib.ACTIVE)
		if resperr == zdlib.RescodeMatchState {
			zdlib.SetDataPortValue(dataPort, code)
			serverReadyStrobe(zdlib.DIR_OUTPUT)
		} else {
			resultStr = "Timeout waiting for CR to be active"
		}
		svrActSig.Write(zdlib.NOT_ACTIVE)
		time.Sleep(respdelay)
	} else {
		resultStr = "Timeout waiting for CA to become inactive"
	}
	return resperr, resultStr
}

func serverReadyStrobe(direction int) {
	// Take the SR line low to indicate that this server has received
	// whatever signal the client sent, or has placed data on the data bus,
	// and is ready to proceed.
	svrRdySig.Write(zdlib.ACTIVE)
	if direction == zdlib.DIR_INPUT {
		time.Sleep(zdlib.StrobeDelayRecv)
	} else {
		time.Sleep(zdlib.StrobeDelaySend)
	}
	svrRdySig.Write(zdlib.NOT_ACTIVE)
}

/*
==========================================================================
-----  MAIN                                                          -----
==========================================================================
*/
func main() {
	gpioErr := rpio.Open()
	if gpioErr != nil {
		log.Fatal("Could not open GPIO")
	}

	// command-line flags
	//flag.StringVar(&filepath, "f", filepath, "filename (with full path)")
	flag.BoolVar(&verbose, "v", verbose, "verbose mode")
	flag.Parse()

	logfh, logerr := os.OpenFile(logFile, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	if logerr != nil {
		log.Fatal("Could not open log file")
	}
	defer logfh.Close()
	log.SetOutput(logfh)

	zdlib.LogMessage(verbose, "ZolaDOS - version", version)
	irq.Output()
	irq.Write(rpio.Low)
	intsel.Output()
	clearInterrupt()
	led.Output()
	led.Write(rpio.Low)
	zdlib.SetDataPortDirection(dataPort, zdlib.DIR_INPUT)
	clActSig.Input()
	clRdySig.Input()
	clOnlineSig.Input()
	svrRdySig.Output()
	svrActSig.Output()
	svrRdySig.PullUp()
	svrActSig.PullUp()
	svrRdySig.Write(zdlib.NOT_ACTIVE)
	svrActSig.Write(zdlib.NOT_ACTIVE)

	standbyLoop := true
	//serverReadyStrobe()
	//reader := bufio.NewReader(os.Stdin)
	clientOnline := zdlib.OFFLINE
	changed := false
	clientOnlineLastState := zdlib.OFFLINE
	zdlib.PrintLine(verbose)
	//--------------------------------------------------------------------------
	//----- MAIN LOOP                                                      -----
	//--------------------------------------------------------------------------
	for standbyLoop {
		clientOnline, changed = zdlib.CheckClientOnlineState(clOnlineSig, clientOnlineLastState)
		if changed {
			clientOnlineLastState = clientOnline
			if clientOnline == zdlib.ONLINE {
				zdlib.LogMessage(verbose, "--- zdlib.ONLINE ---")
			} else {
				zdlib.LogMessage(verbose, "--- zdlib.OFFLINE ---")
			}
		}
		if clientOnline == zdlib.ONLINE {
			activeState := clActSig.Read() // polling for an /INIT signal from Z64
			if activeState == zdlib.ACTIVE {
				// --- INITIATE ---
				// The Z64 has initiated a process.
				zdlib.LogMessage(verbose, "+ Request received")
				result := waitForState(clRdySig, zdlib.ACTIVE)
				switch result {
				case zdlib.RescodeMatchState:
					// At this stage, we're expecting to pick up a code from the
					// Z64 indicating what kind of operation it wants to perform.
					opcode := zdlib.ReadDataPortValue(dataPort)
					serverReadyStrobe(zdlib.DIR_INPUT)
					responseCode := zdlib.RespOK // default/success
					zdlib.LogMessage(verbose, "- code read:", strconv.Itoa(opcode))
					switch opcode {
					// *********************************************************
					// ***** DEL                                           *****
					// *********************************************************
					case zdlib.OPCODE_DEL:
						setLED(zdlib.LED_ON)
						resultStr := ""
						responseCode := zdlib.RespOK
						okayToContinue := true
						// ----- GET FILENAME ----------------------------------
						fName, errFlag, errStr := getString()
						if !errFlag {
							zdlib.LogMessage(verbose, "- Filename:", fName)
						} else {
							resultStr = errStr
							okayToContinue = false
						}
						if okayToContinue {
							zdlib.LogMessage(verbose, "- Deleting...")
							resultStr = "OK"
							filepathname := filepath.Join(fileDir, fName)
							_, exerr := os.Stat(filepathname)
							if exerr != nil {
								responseCode = zdlib.ERR_FILENOTFOUND
								resultStr = "File not found"
							} else {
								zdlib.LogMessage(verbose, "- Deleting file:", filepathname)
								remerr := os.Remove(filepathname)
								if remerr != nil {
									responseCode = zdlib.ERR_FILE_DEL
									resultStr = "Failed to delete file"
								}
							}
							_, resultStr = sendResponseCode(responseCode, zdlib.LoadResponseDelay)
						}
						zdlib.LogMessage(verbose, resultStr)
						setLED(zdlib.LED_OFF)
					// *********************************************************
					// ***** LOAD                                          *****
					// *********************************************************
					case zdlib.OPCODE_LOAD, zdlib.OPCODE_DLOAD, zdlib.OPCODE_XLOAD:
						//zdlib.LogMessage("+ FILENAME")
						setLED(zdlib.LED_ON)
						okayToContinue := true
						fName, errFlag, errStr := getString()
						if !errFlag {
							switch opcode {
							case zdlib.OPCODE_LOAD:
								fileName = fName + ".EXE"
							case zdlib.OPCODE_XLOAD:
								fileName = fName + ".ROM"
							default:
								fileName = fName
							}
							zdlib.LogMessage(verbose, "- Filename:", fileName)
						} else {
							zdlib.LogMessage(verbose, errStr)
							okayToContinue = false
						}
						if okayToContinue {
							//zdlib.LogMessage("+ SERVER RESPONSE")
							byteCount := 0
							readErr := zdlib.RespOK
							fileOkay := true
							resultStr := "OK"

							filepathname := filepath.Join(fileDir, fileName)
							zdlib.LogMessage(verbose, "- Loading file:", filepathname)
							fh, ferr := os.Open(filepathname)
							if ferr != nil {
								zdlib.LogMessage(verbose, ferr.Error())
								responseCode = zdlib.RespErrOpenFile
								fileOkay = false
								resultStr = "Error opening file"
							}
							defer fh.Close()
							//time.Sleep(time.Millisecond * 500)
							resperr, respmsg := sendResponseCode(responseCode, zdlib.LoadResponseDelay)
							if fileOkay && resperr == zdlib.RescodeMatchState {
								svrActSig.Write(zdlib.ACTIVE)
								loadLoop := true
								bufferedReader := bufio.NewReader(fh)
								startTime = time.Now()
								/** ---- LOADING LOOP ------------------- */
								for loadLoop {
									dataByte, berr := bufferedReader.ReadByte()
									if berr != nil {
										if berr == io.EOF {
											svrActSig.Write(zdlib.NOT_ACTIVE)
										} else {
											zdlib.LogMessage(verbose, berr.Error())
											readErr = zdlib.ERR_FILE_READ
											resultStr = "Cannot read file"
										}
										loadLoop = false
									} else {
										byteCount++
										readErr, resultStr = sendByte(int(dataByte))
										if readErr > 0 {
											loadLoop = false
											//resultStr = "Error sending data byte"
										}
									}
								} // -- end loading loop -----------------------
								svrActSig.Write(zdlib.NOT_ACTIVE)
								elapsedTime = time.Since(startTime)
							} else {
								zdlib.LogMessage(verbose, respmsg)
							}
							if readErr > 0 {
								zdlib.LogMessage(verbose, "*** ERROR:", strconv.Itoa(readErr), resultStr, "***")
							} else {
								processDone(byteCount, resultStr)
							}
						}
						setLED(zdlib.LED_OFF)
					// *********************************************************
					// ***** LOAD (paged)                                  *****
					// *********************************************************
					// case zdlib.OPCODE_PLOAD:
					// 	zdlib.LogMessage(verbose, "- Paged load")
					// 	okayToContinue := true
					// 	fileName, errFlag, errStr := getString()
					// 	if !errFlag {
					// 		zdlib.LogMessage(verbose, "- Filename:", fileName)
					// 	} else {
					// 		zdlib.LogMessage(verbose, errStr)
					// 		okayToContinue = false
					// 	}
					// 	if okayToContinue {
					// 		//byteCount := 0
					// 		//chunkCount := 0
					// 	}

					// *********************************************************
					// ***** LS                                            *****
					// *********************************************************
					case zdlib.OPCODE_LS:
						setLED(zdlib.LED_ON)
						result := 0
						zdlib.LogMessage(verbose, "- List storage")
						svrRdySig.Write(zdlib.NOT_ACTIVE) // Just to be sure
						svrActSig.Write(zdlib.ACTIVE)
						//time.Sleep(time.Microsecond * 1000)
						files, lserr := os.ReadDir(fileDir)
						if lserr != nil {
							result = zdlib.RespErrLSfail
							zdlib.LogMessage(verbose, "Failed to list files locally", strconv.Itoa(result))
						}
						zdlib.SetDataPortDirection(dataPort, zdlib.DIR_OUTPUT)
						for _, file := range files {
							//shortName := strings.Split(file.Name(), ".")[0]
							//fnLen := len([]rune(shortName))
							fnLen := len(file.Name())
							fileErr := false
							if fnLen < zdlib.MaxFilenameLen {
								for i := 0; i < fnLen; i++ {
									byteErr, _ := sendByte(int(file.Name()[i]))
									if byteErr > 0 {
										fileErr = true
									}
								}
								if !fileErr {
									nulErr, _ := sendByte(0)
									if nulErr > 0 {
										fileErr = true
									}
								}
							}
							if fileErr {
								result = zdlib.FnameSendErr
								break
							}
						}
						// All files sent
						endErr, endStr := sendByte(zdlib.DataEndCode)
						if endErr != 0 {
							zdlib.LogMessage(verbose, endStr)
						}
						// HERE WE SHOULD SEND THE RESULT TO THE PI AS A
						// CONFIRMATION
						svrActSig.Write(zdlib.NOT_ACTIVE)
						setLED(zdlib.LED_OFF)
					// *********************************************************
					// ***** OPEN                                          *****
					// *********************************************************
					case zdlib.OPCODE_OPENR, zdlib.OPCODE_OPENW:
						/* https://pkg.go.dev/io#ReadFull
						ReadFull reads exactly len(buf) bytes from r into buf. It
						returns the number of bytes copied and an error if fewer
						bytes were read. The error is EOF only if no bytes were
						read. If an EOF happens after reading some but not all the
						bytes, ReadFull returns ErrUnexpectedEOF. On return, n ==
						len(buf) if and only if err == nil. If r returns an error
						having read at least len(buf) bytes, the error is dropped.

						r := strings.NewReader("some io.Reader stream to be read\n")
						buf := make([]byte, 4)
						if _, err := io.ReadFull(r, buf); err != nil {
							log.Fatal(err)
						}
						fmt.Printf("%s\n", buf)

						// minimal read size bigger than io.Reader stream
						longBuf := make([]byte, 64)
						if _, err := io.ReadFull(r, longBuf); err != nil {
							fmt.Println("error:", err)
						}
						*/
						/*setLED(zdlib.LED_ON)
						resultStr := ""
						okayToContinue := true
						fName, errFlag, errStr := getString()
						if !errFlag {

						} else {
							resultStr = errStr
							okayToContinue = false
						}
						if okayToContinue {
							fh, ferr := os.Open(filepathname)
							if ferr != nil {
								zdlib.LogMessage(verbose, ferr.Error())
								responseCode = zdlib.RespErrOpenFile
								fileOkay = false
								resultStr = "Error opening file"
							}
							defer fh.Close()
							//time.Sleep(time.Millisecond * 500)
							resperr, respmsg := sendResponseCode(responseCode, zdlib.LoadResponseDelay)
							if fileOkay && resperr == zdlib.RescodeMatchState {
								svrActSig.Write(zdlib.ACTIVE)
								loadLoop := true
								bufferedReader := bufio.NewReader(fh)
							}
						}
						setLED(zdlib.LED_OFF)
						*/

					// *********************************************************
					// ***** SAVE                                          *****
					// *********************************************************
					case zdlib.OPCODE_DUMP_CRT, zdlib.OPCODE_DUMP_OVR,
						zdlib.OPCODE_DUMP_APP,
						zdlib.OPCODE_SAVE_CRT, zdlib.OPCODE_SAVE_OVR,
						zdlib.OPCODE_SAVE_APP,
						zdlib.OPCODE_SAVE_DATC, zdlib.OPCODE_SAVE_DATO,
						zdlib.OPCODE_SAVE_DATA:
						setLED(zdlib.LED_ON)
						okayToContinue := true
						resultStr := "OK"
						zdlib.LogMessage(verbose, "+ Saving")
						saveMode := 0
						inBuf := make([]byte, 0) // input buffer
						switch opcode {
						case zdlib.OPCODE_SAVE_CRT, zdlib.OPCODE_SAVE_DATC, zdlib.OPCODE_DUMP_CRT:
							saveMode = os.O_WRONLY | os.O_CREATE
						case zdlib.OPCODE_SAVE_OVR, zdlib.OPCODE_SAVE_DATO, zdlib.OPCODE_DUMP_OVR:
							saveMode = os.O_WRONLY | os.O_TRUNC | os.O_CREATE
						case zdlib.OPCODE_SAVE_APP, zdlib.OPCODE_SAVE_DATA, zdlib.OPCODE_DUMP_APP:
							saveMode = os.O_WRONLY | os.O_APPEND | os.O_CREATE
						default:
							saveMode = os.O_WRONLY | os.O_CREATE
						}
						// ----- GET FILENAME ----------------------------------
						fName, errFlag, errStr := getString()
						if !errFlag {
							if opcode == zdlib.OPCODE_SAVE_CRT || opcode == zdlib.OPCODE_SAVE_OVR || opcode == zdlib.OPCODE_SAVE_APP {
								fileName = fName + ".EXE"
							} else if opcode == zdlib.OPCODE_DUMP_CRT || opcode == zdlib.OPCODE_DUMP_OVR || opcode == zdlib.OPCODE_DUMP_APP {
								fileName = fName + ".BIN"
							} else {
								fileName = fName
							}
							zdlib.LogMessage(verbose, "- Filename:", fileName)
						} else {
							resultStr = errStr
							okayToContinue = false
						}
						if okayToContinue {
							fileErr := 0
							filepathname := filepath.Join(fileDir, fileName)
							zdlib.LogMessage(verbose, "- Saving to file:", filepathname)
							writeOK := true
							if opcode == zdlib.OPCODE_SAVE_CRT {
								// Check if file already exists
								_, exerr := os.Stat(filepathname)
								if exerr == nil {
									writeOK = false
									fileErr = zdlib.ERR_FILE_EXISTS
									zdlib.LogMessage(verbose, "! File exists!")
								}
							}
							if fileErr == 0 {
								fh, err := os.OpenFile(filepathname, saveMode, 0644)
								if err != nil {
									fileErr = zdlib.ERR_FILE_OPEN
									zdlib.LogMessage(verbose, "- Could not create file:", filepathname)
									resultStr = "File open error"
									writeOK = false
								}
								defer fh.Close()
								// ----- SEND RESPONSE------------------------------
								resperr, respmsg := sendResponseCode(fileErr, zdlib.SaveResponseDelay)
								if resperr != zdlib.RescodeMatchState {
									writeOK = false
									zdlib.LogMessage(verbose, respmsg)
								}
								// ----- RECEIVE DATA-------------------------------
								zdlib.SetDataPortDirection(dataPort, zdlib.DIR_INPUT)
								byteCount := 0
								saveErr := false
								resperr = waitForState(clActSig, zdlib.ACTIVE)
								if resperr == zdlib.RescodeMatchState {
									startTime = time.Now()
									// --- DATA TRANSFER LOOP ------------------
									for writeOK {
										resperr = waitForState(clRdySig, zdlib.ACTIVE)
										if resperr == zdlib.RescodeMatchState {
											inBuf = append(inBuf, byte(zdlib.ReadDataPortValue(dataPort)))
											byteCount++
											serverReadyStrobe(zdlib.DIR_INPUT)
											//svrRdySig.Write(zdlib.ACTIVE)
											resperr = waitForState(clRdySig, zdlib.NOT_ACTIVE)
											if resperr == zdlib.RescodeMatchState {
												// svrRdySig.Write(zdlib.ACTIVE)
											} else {
												resultStr = "Got tired of waiting for CR to be active"
												saveErr = true
												writeOK = false
											}
										}
										caState := clActSig.Read()
										if caState == zdlib.NOT_ACTIVE {
											writeOK = false
										}
									}
									// -----------------------------------------
									_, wrerr := fh.Write(inBuf)
									if wrerr != nil {
										saveErr = true
									}
									if !saveErr {
										elapsedTime = time.Since(startTime)
										processDone(byteCount, resultStr)
									} else {
										zdlib.LogMessage(verbose, resultStr)
									}
								} else {
									zdlib.LogMessage(verbose, "! Got bored waiting for CA to be active")
								}
							} else {
								sendResponseCode(fileErr, zdlib.SaveResponseDelay)
								svrRdySig.Write(zdlib.NOT_ACTIVE)
								svrActSig.Write(zdlib.NOT_ACTIVE)
							}
						}
						setLED(zdlib.LED_OFF)
					default:
						zdlib.LogMessage(verbose, "*** Unknown opcode ***")
					}
					svrRdySig.Write(zdlib.NOT_ACTIVE)
					svrActSig.Write(zdlib.NOT_ACTIVE)
				case zdlib.RescodeTerm:
					zdlib.LogMessage(verbose, "Job done")
				case zdlib.RescodeTimeout:
					fmt.Println("*** Timed out ***")
				default:
					fmt.Println("Well, this isn't right")
				}
				zdlib.SetDataPortDirection(dataPort, zdlib.DIR_INPUT)
				time.Sleep(time.Millisecond * 100)
				// fmt.Print("Press <RETURN> to continue...")
				// key, _ := reader.ReadString('\n')
				//zdlib.LogMessage("- waiting for next request...")
				zdlib.PrintLine(verbose)
			}
		}
	} // standbyLoop
}
