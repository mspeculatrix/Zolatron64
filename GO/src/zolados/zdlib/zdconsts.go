package zdlib

import (
	"time"

	"github.com/stianeikeland/go-rpio"
)

const (
	StrobeDelaySend   = time.Microsecond * 100 // 200µs works - length of strobe
	StrobeDelayRecv   = time.Microsecond * 800
	TimeoutDelay      = time.Millisecond * 100 // 100ms works
	LoadResponseDelay = time.Microsecond * 100 // 100µs works, try smaller
	SaveResponseDelay = time.Microsecond * 100
	IrqDelay          = time.Microsecond * 100
	StringReadDelay   = time.Millisecond * 1 // was 500µs but getting duplicate chars

	MaxFilenameLen = 15
	FilesPerLine   = 4

	RescodeErr        = 255
	RescodeMatchState = 1
	RescodeTimeout    = 2
	RescodeTerm       = 4

	ERR_FILE_READ    = 7  // Match with error codes in Z64 code:
	ERR_FILE_LIST    = 13 // cfg_main.asm
	ERR_FILE_EXISTS  = 22
	ERR_FILE_OPEN    = 23
	ERR_FILE_DEL     = 24
	ERR_FILENOTFOUND = 25
	ERR_FILE_BOUNDS  = 26

	DataEndCode  = 255
	OPCODE_LOAD  = 2  // LOAD - for loading executable .EXE files
	OPCODE_DLOAD = 3  // DATA LOAD - for loading data files - no ext added
	OPCODE_XLOAD = 4  // LOAD executable into extended memory - ROM images
	OPCODE_LS    = 8  // LIST STORAGE
	OPCODE_OPENR = 10 // OPEN file for reading
	OPCODE_OPENW = 11 // OPEN file for writing
	OPCODE_CLOSE = 12 // CLOSE file

	OPCODE_RBLK  = 30 // Read block
	OPCODE_RBYTE = 31 // Read byte
	OPCODE_RSTR  = 32 // Read nul-terminated string
	OPCODE_WBLK  = 40 // Write block
	OPCODE_WBYTE = 41 // Write byte
	OPCODE_WSTR  = 42 // Write nul-terminated string

	OPCODE_DEL = 72 // Delete file
	OPCODE_MV  = 96 // Move (rename) file

	//Following save modes will cause ZolaDOS to append '.BIN' to the filename.
	OPCODE_DUMP_CRT = 128 // Save - create (no overwrite)
	OPCODE_DUMP_OVR = 129 // Save - overwrite
	OPCODE_DUMP_APP = 130 // Save - append
	// No extension appended - command must use full filename
	OPCODE_SAVE_DATC = 135 // Save - create file, no overwrite
	OPCODE_SAVE_DATO = 136 // Save - overwite okay
	OPCODE_SAVE_DATA = 137 // Save - append
	// Following save modes will cause ZolaDOS to append '.EXE' to the filename.
	OPCODE_SAVE_CRT = 140 // Save - create (no overwrite)
	OPCODE_SAVE_OVR = 141 // Save - overwrite
	OPCODE_SAVE_APP = 142 // Save - append

	DIR_INPUT  = 0
	DIR_OUTPUT = 1
	ACTIVE     = rpio.Low
	NOT_ACTIVE = rpio.High
	ONLINE     = rpio.High
	OFFLINE    = rpio.Low
	LED_ON     = rpio.High
	LED_OFF    = rpio.Low

	RespOK          = 0
	RespErrOpenFile = 11
	RespErrLSfail   = 12
	FnameSendErr    = 13 // ??????????

	ChunkSize = 256
)
