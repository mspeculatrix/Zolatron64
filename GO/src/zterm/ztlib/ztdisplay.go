package ztlib

import (
	"fmt"
	"strings"
)

func PrintPrompt(state ConfigState) {
	if state.ConvertToUpper == 1 {
		fmt.Print("Z>")
	} else {
		fmt.Print("z>")
	}
}

func ReturnModeStr(state ConfigState) (modeStr string) {
	modeStr = "RTN"
	if state.ReturnMode == NULL {
		modeStr = "NULL"
	}
	return modeStr
}

func ShowFkeys() {
	fmt.Println("<esc> switch to CMD mode")
	fmt.Println("F1    show status            F2    toggle NULL/RTN mode for <return>")
	fmt.Println("F3    send test message      F4    send NULL")
	fmt.Println("F5    set test message       F6    toggle keycodes")
	fmt.Println("                             F8    reset Zolatron")
	fmt.Println("F9    toggle uppercase       F10   quit")
}

func ShowKeycodesMode(state ConfigState) {
	fmt.Println("\n-- Show keycodes is", ToggleStates[state.ShowKeyCodes], " --")
}

func ShowReturnMode(state ConfigState) {
	fmt.Println("\n-- Using", ReturnModeStr(state), "mode for <return> key --")
}

func ShowStatus(state ConfigState, cfg AppConfig) {
	fmt.Printf("Version   : %-15s  Log file    : %s\n", cfg.Version, cfg.LogFile)
	fmt.Printf("Port      : %-15s  Input mode  : %s\n", cfg.ComPort, strings.ToUpper(state.Imode))
	fmt.Printf("Baud rate : %-15d  Return mode : %s\n", cfg.BaudRate, ReturnModeStr(state))
	fmt.Printf("Uppercase : %-15s  Test msg    : %s\n", ToggleStates[state.ConvertToUpper], state.TestMsg)
	if state.Imode == "raw" {
		fmt.Println("Function keys:")
		ShowFkeys()
	}
	PrintPrompt(state)
}

func ShowUpperMode(state ConfigState) {
	fmt.Println("\n-- Conversion to UPPERCASE is", ToggleStates[state.ConvertToUpper], " --")
}
