; Main configuration file

STDIN_BUF      = $0300 ; Input buffer start address
STDOUT_BUF     = $0380 ; Output buffer start address
STDIN_IDX      = $037F ; Location of input buffer index
STDOUT_IDX     = $03FF ; Location of output buffer index
STR_BUF_LEN    = 120   ; size of buffers. We actually have 127 bytes available
STR_BUF_MAX    = 127   ; but this leaves some headroom.

\-------------------------------------------------------------------------------
\ ERROR CODES
\-------------------------------------------------------------------------------
; Must be in the same order as the error tables in data_tables.asm.
; Must also be sequential, starting at 1 (0 means no error).
COMMAND_ERR_CODE      = 1
HEX_TO_BIN_ERR_CODE   = COMMAND_ERR_CODE + 1			  ; 2
PARSE_ERR_CODE        = HEX_TO_BIN_ERR_CODE + 1			; 3
READ_HEXBYTE_ERR_CODE = PARSE_ERR_CODE + 1				  ; 4
SYNTAX_ERR_CODE       = READ_HEXBYTE_ERR_CODE + 1		; 5  Syntax error
FREAD_ERR_CODE        = SYNTAX_ERR_CODE + 1				  ; 6  File read error
FREAD_TO_SR			      = FREAD_ERR_CODE + 1		      ; 7  SR Timeout
FREAD_TO_SA			      = FREAD_TO_SR + 1				      ; 8  SA Timeout
FREAD_TO_SRO			    = FREAD_TO_SA + 1		          ; 9  SR Off Timeout
FREAD_TO_SAO			    = FREAD_TO_SRO + 1				    ; 10 A  SA Off Timeout
FREAD_SVR_OPEN        = FREAD_TO_SAO + 1            ; 11 B  File open err
FILE_LIST_ERR         = FREAD_SVR_OPEN + 1          ; 12 C  LS error
FN_CHAR_ERR_CODE      = FILE_LIST_ERR + 1           ; 13 D  Bad character
FN_LEN_ERR_CODE       = FN_CHAR_ERR_CODE + 1        ; 14 E  Bad filename length
ERR_EOB               = FN_LEN_ERR_CODE + 1         ; 15 F  End of buffer
ERR_NAN               = ERR_EOB + 1                 ; 16 10 Not a number
ERR_EXTMEM_WR         = ERR_NAN + 1                 ; 17 11 Ext mem write err
ERR_EXTMEM_BANK       = ERR_EXTMEM_WR + 1           ; 18 12 Ext mem bank err
ERR_EXTMEM_EXEC       = ERR_EXTMEM_BANK + 1         ; 19 13 Ext mem exec err
ERR_ADDR              = ERR_EXTMEM_EXEC + 1         ; 20 14 Address error
ERR_FILE_EXISTS       = ERR_ADDR + 1                ; 21 15 File exists error
ERR_FILE_OPEN         = ERR_FILE_EXISTS + 1         ; 22 16 Error opening file
ERR_DELFILE_FAIL      = ERR_FILE_OPEN + 1           ; 23 17 Failed delete file
ERR_FILENOTFOUND      = ERR_DELFILE_FAIL + 1        ; 24 18 File not found
ERR_FILE_BOUNDS       = ERR_FILENOTFOUND + 1
STDIN_BUF_EMPTY       = ERR_FILE_BOUNDS + 1        ; 25 19 Input buffer empty
ERR_NO_EXECUTABLE     = STDIN_BUF_EMPTY + 1         ; 26 1A No exec prog loaded
ERR_PRT_STATE_OL      = ERR_NO_EXECUTABLE + 1       ; 27 1B Printer offline
ERR_PRT_STATE_PE      = ERR_PRT_STATE_OL + 1
ERR_PRT_STATE_ERR     = ERR_PRT_STATE_PE + 1
ERR_PRT_NOT_PRESENT   = ERR_PRT_STATE_ERR + 1       ; Printer board not present

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Function Address Table
\ Requires corresponding entries in:
\    - z64-main.asm   - OS Call Jump Table
\    - os_call_vectors.asm - map functions to vectors
\    - cfg_page_2.asm - OS Indirection Table
\-------------------------------------------------------------------------------
; READ
OSGETKEY   = $FF00
OSRDASC    = OSGETKEY + 3
OSRDBYTE   = OSRDASC + 3
OSRDCH     = OSRDBYTE + 3
OSRDHBYTE  = OSRDCH + 3
OSRDHADDR  = OSRDHBYTE + 3
OSRDINT16  = OSRDHADDR + 3
OSRDFNAME  = OSRDINT16 + 3
OSRDSTR    = OSRDFNAME + 3
; WRITE
OSWRBUF    = OSRDSTR + 3
OSWRCH     = OSWRBUF + 3
OSWRERR    = OSWRCH + 3
OSWRMSG    = OSWRERR + 3
OSWRSBUF   = OSWRMSG + 3
OSSOAPP    = OSWRSBUF + 3
OSSOCH     = OSSOAPP + 3
; CONVERSIONS
OSB2BIN    = OSSOCH + 3
OSB2HEX    = OSB2BIN + 3
OSB2ISTR   = OSB2HEX + 3
OSHEX2B    = OSB2ISTR + 3
OSU16HEX   = OSHEX2B + 3
OSHEX2DEC  = OSU16HEX + 3
; LCD
OSLCDCH    = OSHEX2DEC + 3
OSLCDCLS   = OSLCDCH + 3
OSLCDERR   = OSLCDCLS + 3
OSLCDMSG   = OSLCDERR + 3
OSLCDB2HEX = OSLCDMSG + 3
OSLCDSBUF  = OSLCDB2HEX + 3
OSLCDSC    = OSLCDSBUF + 3
OSLCDWRBUF = OSLCDSC + 3
; PRINTER
OSPRTBUF   = OSLCDWRBUF + 3
OSPRTCH    = OSPRTBUF + 3
OSPRTCHK   = OSPRTCH + 3
OSPRTINIT  = OSPRTCHK + 3
OSPRTMSG   = OSPRTINIT + 3
OSPRTSBUF  = OSPRTMSG + 3
\OSPRTSTMSG = OSPRTSBUF + 3
; ZOLADOS
OSZDDEL    = OSPRTSBUF + 3
OSZDLOAD   = OSZDDEL + 3
OSZDSAVE   = OSZDLOAD + 3
; MISC
OSDELAY    = OSZDSAVE + 3
OSUSRINT   = OSDELAY + 3

OSSFTRST   = $FFF4         ; Use direct JMP with these (not indirected/vectored)
OSHRDRST   = $FFF7

USR_START = $0800          ; Address where user programs load
USR_END   = $7FFF          ; Top of user memory
ROM_START = $C000          ; Start of ROM memory
EXTMEM_SLOT_SEL = $BFE0    ; Write to this address to select memory slot (0-15)
EXTMEM_START    = $8000    ; This is where extended memory lives
EXTMEM_END      = $9FFF    ; Last writable byte in extended memory bank

LCD_TYPE_16x2 = 0
LCD_TYPE_20x4 = 1

; Code headers. These are offsets from the start of user code (which is at
; USR_START for RAM-based code and EXTEM_LOC for ROM-based code)
CODEHDR_TYPE  = $03
CODEHDR_ENTRY = $04
CODEHDR_RST   = $06
CODEHDR_END   = $08
CODEHDR_NAME  = $0D

TYPECODE_BOOT = 'B'                   ; Boot ROM
TYPECODE_DATA = 'D'                   ; Data file
TYPECODE_EXEC = 'E'                   ; Executable code
TYPECODE_OSEX = 'X'                   ; OS extension
TYPECODE_OVLY = 'O'                   ; Program overlay

EOCMD_SECTION = 0                     ; End of section marker for command table
EOTBL_MKR     = 255                   ; End of table marker

CHR_LINEEND   = 10        ; ASCII code for line end - here we're using line feed
CHR_SPACE     = 32

EQUAL = 1
MORE_THAN = 2
LESS_THAN = 0

; STDIN FLAGS
STDIN_NUL_RCVD_FL = %00000001    ; We've received a null terminator
STDIN_DAT_RCVD_FL = %00000010    ; We've received some data
STDIN_BUF_FULL_FL = %00000100    ; Input buffer is full
STDIN_CLEAR_FLAGS = %11110000    ; To be ANDed with reg to clear RX flags

; PROCESS FLAGS - for use with SYS_REG
PROC_ZD_INT_FL    = %10000000    ; Interrupt signal received from ZolaDOS

; Values for stream select. STREAM_SELECT_REG address is defined in
; cfg_page_5.asm.
; Low nibble - Input Streams
; Bit       Stream
;  0        Keyboard
;  1        Serial (ACIA)
;  2        -- reserved --
;  3        -- reserved --
; High nibble - Output Streams
;  4        Screen
;  5        Serial (ACIA)
;  6        Serial2 (DUART)
;  7        Printer
; Doesn't make much sense to use the LCD as a stream, so this is treated as a
; device in its own right, although its functions need to be accessible via
; OS calls.
;STR_SEL_SERIAL  = %00100010     ; STA to register to set
;STR_SEL_OUT_SER = %00101111     ; AND with register to set
;STR_SEL_OUT_PRT = %10001111     ; AND with register to set

MACRO LOAD_MSG msg_addr
  lda #<msg_addr                              ; LSB of message
  sta MSG_VEC
  lda #>msg_addr                              ; MSB of message
  sta MSG_VEC+1
ENDMACRO

MACRO PRT_MSG msg_addr, func_addr
  lda #<msg_addr                              ; LSB of message
  sta MSG_VEC
  lda #>msg_addr                              ; MSB of message
  sta MSG_VEC+1
  jsr func_addr
ENDMACRO

MACRO NEWLINE
  pha
  lda #CHR_LINEEND
  jsr OSWRCH
  pla
ENDMACRO

MACRO CLEAR_INPUT_BUF
  stz STDIN_IDX
  lda STDIN_STATUS_REG ; reset the nul received flag
  and #STDIN_CLEAR_FLAGS
  sta STDIN_STATUS_REG
ENDMACRO

MACRO SERIAL_PROMPT
  lda #<prompt_msg                              ; LSB of message
  sta MSG_VEC
  lda #>prompt_msg                              ; MSB of message
  sta MSG_VEC+1
  jsr OSWRMSG
ENDMACRO

MACRO STDOUT_TO_MSG_VEC
  lda #<STDOUT_BUF
  sta MSG_VEC
  lda #>STDOUT_BUF
  sta MSG_VEC+1
ENDMACRO

MACRO STR_BUF_TO_MSG_VEC
  lda #<STR_BUF
  sta MSG_VEC
  lda #>STR_BUF
  sta MSG_VEC+1
ENDMACRO
