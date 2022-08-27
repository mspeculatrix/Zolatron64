; Main configuration file

STDIN_BUF      = $0300 ; Input buffer start address
STDOUT_BUF     = $0380 ; Output buffer start address
STDIN_IDX      = $037F ; Location of input buffer index
STDOUT_IDX     = $03FF ; Location of output buffer index
STR_BUF_LEN    = 120   ; size of buffers. We actually have 127 bytes available
STR_BUF_MAX    = 127   ; but this leaves some headroom.

; ERROR CODES: must be in the same order as the error tables in data_tables.asm.
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
ERR_ADDR              = ERR_EXTMEM_BANK + 1         ; 19 13 Address error
ERR_FILE_EXISTS       = ERR_ADDR + 1                ; 20 14 File exists error
ERR_FILE_OPEN         = ERR_FILE_EXISTS + 1         ; 21 15 Error opening file
ERR_DELFILE_FAIL      = ERR_FILE_OPEN + 1           ; 22 16 Failed delete file
ERR_FILENOTFOUND      = ERR_DELFILE_FAIL + 1        ; 23 17 File not found

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Function Address Table
\ Jump table for OS calls. Requires corresponding entries in:
\    - z64-main.asm   - OS Call Jump Table
\    - os_call_vectors.asm - map functions to vectors
\    - cfg_page_2.asm - OS Indirection Table
\-------------------------------------------------------------------------------
; READ
OSRDHBYTE = $FF00
OSRDHADDR = OSRDHBYTE + 3
OSRDCH    = OSRDHADDR + 3
OSRDINT16 = OSRDCH + 3
OSRDFNAME = OSRDINT16 + 3
; WRITE
OSWRBUF   = OSRDFNAME + 3
OSWRCH    = OSWRBUF + 3
OSWRERR   = OSWRCH + 3
OSWRMSG   = OSWRERR + 3
OSWRSBUF  = OSWRMSG + 3
OSSOAPP   = OSWRSBUF + 3
; CONVERSIONS
OSB2HEX   = OSSOAPP + 3
OSB2ISTR  = OSB2HEX + 3
OSHEX2B   = OSB2ISTR + 3
OSU16HEX  = OSHEX2B + 3
OSHEX2DEC = OSU16HEX + 3
; LCD
OSLCDCH   = OSHEX2DEC + 3
OSLCDCLS  = OSLCDCH + 3
OSLCDERR  = OSLCDCLS + 3
OSLCDMSG  = OSLCDERR + 3
OSLCDB2HEX = OSLCDMSG + 3
OSLCDSBUF = OSLCDB2HEX + 3
OSLCDSC   = OSLCDSBUF + 3
; PRINTER
OSPRTBUF  = OSLCDSC + 3
OSPRTCH   = OSPRTBUF + 3
OSPRTINIT = OSPRTCH + 3
OSPRTMSG  = OSPRTINIT + 3
OSPRTSBUF = OSPRTMSG + 3
OSPRTSTMSG = OSPRTSBUF + 3
; ZOLADOS
OSZDDEL   = OSPRTSTMSG + 3
OSZDLOAD  = OSZDDEL + 3
OSZDSAVE  = OSZDLOAD + 3
; MISC
OSDELAY   = OSZDSAVE + 3
OSUSRINT  = OSDELAY + 3

OSSFTRST  = $FFF4         ; Use direct JMP with these (not indirected/vectored)
OSHRDRST  = $FFF7

USR_PAGE = $0800          ; Address where user programs load
ROMSTART = $C000
EXTMEM_SLOT_SEL  = $BFE0  ; Write to this address to select memory slot (0-15)
EXTMEM_LOC = $8000        ; This is where extended memory lives

DATA_TYPE_EXE = 1
DATA_TYPE_OVR = 2
DATA_TYPE_DAT = 3
DATA_TYPE_OSX = 4
MAX_DATA_TYPE = 4

; Code headers. These are offsets from the start of user code (which is at
; USR_PAGE for RAM-based code and FLASHMEM_LOC for Flash-based code)
CODEHDR_RST  = $05
CODEHDR_END  = $07
CODEHDR_NAME = $0D

EOCMD_SECTION = 0                   ; End of section marker for command table
EOTBL_MKR     = 255                 ; End of table marker

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

; PROCESS FLAGS - for use with PROC_REG
PROC_ZD_INT_FL    = %01000000    ; Interrupt signal received from ZolaDOS

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
  lda #CHR_LINEEND
  jsr OSWRCH
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
