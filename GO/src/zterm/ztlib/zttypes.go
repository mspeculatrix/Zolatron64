package ztlib

type AppConfig struct {
	Version  string
	ComPort  string
	BaudRate int
	LogFile  string
}

type ConfigState struct {
	Imode, LogState, TestMsg     string
	ReturnMode                   byte
	LogSession                   bool
	ConvertToUpper, ShowKeyCodes int
}
