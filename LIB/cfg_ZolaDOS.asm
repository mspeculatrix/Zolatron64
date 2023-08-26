\ cfg_ZolaDOS.asm

\ Configuration for ZolaDOS mass storage system.
\ Uses 65C22 VIA B at address $A400.
\   - PORT A is used for 8-bit parallel data - bidirectional.
\   - PORT B is used for control signals - unidirectional.
\ These connect to a Raspberry Pi running the program zolados.
\ The VIA's timers are also reserved for use by ZolaDOS.

ZD_BASE_ADDR = $A400

; 6522 VIA register addresses
ZD_CTRL_PORT = ZD_BASE_ADDR           ; VIA Port B data/instruction register
ZD_CTRL_DDR  = ZD_BASE_ADDR + $02     ; Port B Data Direction Register
ZD_DATA_PORT = ZD_BASE_ADDR + $01     ; VIA Port A data/instruction register
ZD_DATA_DDR  = ZD_BASE_ADDR + $03     ; Port A Data Direction Register

ZD_T1CL  = ZD_BASE_ADDR + $04         ; Timer 1 counter low
ZD_T1CH  = ZD_BASE_ADDR + $05	        ; Timer 1 counter high
ZD_T2CL  = ZD_BASE_ADDR + $08         ; Timer 2 counter low
ZD_T2CH  = ZD_BASE_ADDR + $09	        ; Timer 2 counter high
ZD_ACR   = ZD_BASE_ADDR + $0B		      ; Auxiliary Control register
ZD_IER   = ZD_BASE_ADDR + $0E 	      ; Interrupt Enable Register
ZD_IFR   = ZD_BASE_ADDR + $0D		      ; Interrupt Flag Register

ZD_TIMER_COUNT = $0600                ; Using page 6 as workspace memory
ZD_FSTATE      = ZD_TIMER_COUNT + 2   ; for ZolaDOS
ZD_CTRL_REG    = ZD_FSTATE + 1        ; Control register
ZD_WKSPC       = ZD_CTRL_REG + 1      ; General workspace

\ ZD_CTRL_REG
\ Control various ZD functions. It's assumed that only one bit at a time will
\ be set, just prior to a ZD operation, and that this register will be reset to
\ its default value of %00000000 following the operation.
\ Bit 7   - 0 - Include allowance for extension in max filename length check
\           1 - Don't include ext - use shorter filename check
ZD_CTRL_EXCL_EXT = %1000000


ZD_FSTATE_CLOSED    = 0               ; No file open
ZD_FSTATE_OPENR     = 1               ; File has been opened for reading
ZD_FSTATE_OPENW     = 2               ; File has been opened for writing

ZD_OPCODE_LOAD      = 2               ; Load executable .EXE files
ZD_OPCODE_DLOAD     = 3               ; Load data files - no ext added
ZD_OPCODE_XLOAD     = 4               ; Load executable .ROM files
ZD_OPCODE_LS        = 8
ZD_OPCODE_OPENR     = 10              ; Open file for reading
ZD_OPCODE_OPENW     = 11              ; Open file for writing
ZD_OPCODE_CLOSE     = 12

ZD_OPCODE_RBLK      = 30              ; Read block
ZD_OPCODE_RBYTE     = 31              ; Read byte
ZD_OPCODE_RSTR      = 32              ; Read nul-terminated string
ZD_OPCODE_WBLK      = 40              ; Write block
ZD_OPCODE_WBYTE     = 41              ; Write byte
ZD_OPCODE_WSTR      = 42              ; Write nul-terminated string

ZD_OPCODE_DEL       = 72              ; Delete file
ZD_OPCODE_MV        = 96              ; Move (rename) file

; Following save modes will case ZolaDOS to append '.BIN' to the filename.
ZD_OPCODE_DUMP_CRT  = 128             ; Save - create file, no overwrite
ZD_OPCODE_DUMP_OVR  = 129             ; Save - overwrite okay
ZD_OPCODE_DUMP_APP  = 130             ; Save - append
; No extension appended - command must use full filename
ZD_OPCODE_SAVE_DATC = 135             ; Save - create file, no overwrite
ZD_OPCODE_SAVE_DATO = 136             ; Save - overwite okay
ZD_OPCODE_SAVE_DATA = 137             ; Save - append
; Following save modes will case ZolaDOS to append '.EXE' to the filename.
ZD_OPCODE_SAVE_CRT  = 140             ; Save command - create file, no overwrite
ZD_OPCODE_SAVE_OVR  = 141             ; Save - overwrite okay
ZD_OPCODE_SAVE_APP  = 142             ; Save - append

ZD_STREAM_SZ        = 256             ; How many bytes per chunk when streaming

ZD_MIN_FN_LEN     = 3           ; Minimum filename length
ZD_MAX_FN_LEN     = 12          ; Maximum filename length without extension
ZD_MAX_FN_LEN_EX  = 16          ; Maximum filename length with extension
ZD_FILES_PER_LINE = 4           ; Number of filenames to be displayed per line
ZD_FILELIST_TERM  = 255         ; Terminator for end file list

; CA - Client Active
ZD_CA_ON        = %11111110           ; PB0 - AND with PB to set /CA bit low
ZD_CA_OFF       = %00000001           ; PB0 - OR with PB to set /CA bit high
; CO - Client Online - when low, tells RPi that Z64 is booted & available
ZD_CO_ON        = %00000100           ; PB2 - OR with PB to set /CO bit high
ZD_CO_OFF       = %11111011           ; PB2 - AND with PB to set /CO bit low
; CR - Client Ready
ZD_CR_ON        = %11111101           ; PB1 - AND with PB to set /CR bit low
ZD_CR_OFF       = %00000010           ; PB1 - OR with PB to set /CR bit high
; For use with 74LVC4245A - sets direction of level translation
ZD_DDIR_INPUT   = %11110111        ; PB3 - AND with PB to set DATA port to input
ZD_DDIR_OUTPUT  = %00001000        ; PB3 - OR with PB to set DATA port to output

; SR and SA are inputs
ZD_SR_MASK      = %00010000           ; PB4 - AND with PB to read SR signal
ZD_SA_MASK      = %00100000           ; PB5 - AND with PB to read SA signal

; The interrupt select line from the RPi is connected to PB6 on the VIA.
; This should be set high by the RPi before generating an interrupt signal.
; To check for this signal, AND ZD_INT_SEL with ZD_CTRL_PORT
ZD_INT_SEL      = %01000000

ZD_DATA_SET_OUT = %11111111
ZD_DATA_SET_IN  = %00000000
ZD_CTRL_PINDIR  = %00001111

; These values work
;ZD_STROBETIME    = $02EE             ;
;ZD_SIGNALDELAY   = $0280             ; 03E8=1ms
;ZD_TIMEOUT_INTVL = $270E             ; Timer cycles between each interrupt
;ZD_TIMEOUT_LIMIT = $004F             ; Times interrupt fires before we timeout
; Versions for tweaking/experimenting
ZD_STROBETIME    = $0220
; Tried & failed: 0177, 0210
ZD_SIGNALDELAY   = $0270
; Tried & failed: 0140, 0200, 0260
ZD_TIMEOUT_INTVL = $270E              ; No. of timer cycles between interrupts
ZD_TIMEOUT_LIMIT = $010F              ; was 004F Times interrupt fires before timeout

MACRO ZD_SET_CA_ON
  lda ZD_CTRL_PORT
  and #ZD_CA_ON
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_CA_OFF
  lda ZD_CTRL_PORT
  ora #ZD_CA_OFF
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_CO_ON
  lda ZD_CTRL_PORT
  ora #ZD_CO_ON
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_CO_OFF
  lda ZD_CTRL_PORT
  and #ZD_CO_OFF
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_CR_ON
  lda ZD_CTRL_PORT
  and #ZD_CR_ON
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_CR_OFF
  lda ZD_CTRL_PORT
  ora #ZD_CR_OFF
  sta ZD_CTRL_PORT
ENDMACRO

; For use with 74LVC4245A
MACRO ZD_SET_DATADIR_OUTPUT
  lda #ZD_DATA_SET_OUT
  sta ZD_DATA_DDR
  lda ZD_CTRL_PORT
  ora #ZD_DDIR_OUTPUT
  sta ZD_CTRL_PORT
ENDMACRO

MACRO ZD_SET_DATADIR_INPUT
  lda #ZD_DATA_SET_IN
  sta ZD_DATA_DDR
  lda ZD_CTRL_PORT
  and #ZD_DDIR_INPUT
  sta ZD_CTRL_PORT
ENDMACRO

MACRO SET_EXCL_EXT_FLAG
  lda #ZD_CTRL_EXCL_EXT
  sta ZD_CTRL_REG
ENDMACRO
