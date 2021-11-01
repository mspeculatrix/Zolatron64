; Zolatron 64
;
; Experimental ROM code for Zolatron 6502-based microcomputer.
;
; From previous versions:
;   - prints 'Zolatron 64' to the 16x2 LCD display on start up
;   - sends a start-up message and prompt across the serial connection
;   - receives on the serial port. It prints incoming strings to the LCD.
;     These strings should be terminated with a null (ASCII 0) or 
;     carriage return (ASCII 13).
;	  - checks for size of receive buffer, to prevent overflows. (NOT TESTED)
;   - has additional LCD print routines.
; In this version:
;   - added the byte_to_hex_str subroutine
;   - WORK IN PROGRESS:
;     - Adding command parsing
;
; BUT: There's no flow control. And because we're running on a 1MHz clock, it's
; easily overwhelmed by incoming data. To make this work, the sending terminal
; must have a delay between characters (easy to set in Minicom or CuteCom).
; I'm currently using 10ms. I'm happy to live with this restriction for now.
; This post was helpful: 
; https://www.reddit.com/r/beneater/comments/qbilsu/6551_acia_question/
;
; TO DO:
;   - Maybe implement flow control to manage incoming data.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i z64-<version>.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-ROM-<version>.bin

; command token values
CMD_TKN_STAR = $80                  ; ??
CMD_TKN_LM = CMD_TKN_STAR + 1       ; list memory
CMD_TKN_PRT = CMD_TKN_LM + 1        ; print string to LCD
CMD_TKN_VERBOSE = CMD_TKN_PRT +  1
CMD_TKN_VERS = CMD_TKN_VERBOSE + 1  ; show version

EOCMD_SECTION = 0              ; end of command section marker for command table
EOTBL_MKR = 255                ; end of table marker

; 6522 VIA register addresses
VIA_A_PORTA = $A001     ; VIA Port A data/instruction register
VIA_A_DDRA  = $A003     ; Port A Data Direction Register
VIA_A_PORTB = $A000     ; VIA Port B data/instruction register
VIA_A_DDRB  = $A002     ; Port B Data Direction Register

; Vectors & other zero-page addresses
TEST_VAL = $50
FUNC_RESULT = $60
MSG_VEC = $70  ; Address of message to be printed. LSB is MSG_VEC, MSB is +1
TBL_VEC = $72  ; table vector - for searching tables

TEXT_BUF = $07A0      ; general-purpose buffer/scratchpad
TEXT_BUF_SIZE = $40   ; 64 bytes

; ACIA addresses
ACIA_DATA_REG = $B000 ; transmit/receive data register
ACIA_STAT_REG = $B001 ; status register
ACIA_CMD_REG = $B002  ; command register
ACIA_CTRL_REG = $B003 ; control register
UART_RX_BUF = $0400   ; Serial receive buffer start address
UART_TX_BUF = $0300   ; Serial send buffer start address
UART_RX_IDX = $04FF   ; Location of RX buffer index
UART_TX_IDX = $03FF   ; Location of TX buffer index
UART_RX_BUF_LEN = 240 ; size of buffers. We actually have 255 bytes available
UART_RX_BUF_MAX = 255 ; but this leaves some headroom. The MAX values are for
UART_TX_BUF_LEN = 240 ; use in output routines.
UART_TX_BUF_MAX = 255 ; 

CHR_LINEEND   = 10  ; ASCII code for line end - here we're using line feed
CHR_SPACE     = 32
CHR_NUL       = 0

UART_STATUS_REG = $02A0 ; memory byte we'll use to store various flags
; masks for setting/reading/resetting flags
;UART_FL_RX_BUF_DATA = %00000001   ; Receive buffer has data
;UART_FL_RX_DATA_RST = %11111110   ; Reset mask
UART_FL_RX_NUL_RCVD = %00000010   ; we've received a null terminator
; UART_FL_RX_BUF_FULL = %00001000
UART_CLEAR_RX_FLAGS = %11110000   ; to be ANDed with info reg to clear RX flags
UART_FL_TX_BUF_DATA = %00010000   ; TX buffer has data to send
UART_FL_TX_BUF_FULL = %10000000
UART_CLEAR_TX_FLAGS = %00001111   ; to be ANDed with info reg to clear TX flags

; Following are values for the control register, setting eight data bits, 
; no parity, 1 stop bit and use of the internal baud rate generator
UART_8N1_0300 = %10010110
UART_8N1_1200 = %10011000
UART_8N1_2400 = %10011010
UART_8N1_9600 = %10011110
UART_8N1_19K2 = %10011111
; Value for the command register: No parity, echo normal, RTS low with no 
; transmit IRQ, IRQ enabled on receive, data terminal ready
ACIA_CMD_CFG = %00001001
; Mask values to be ANDed with status reg to check state of ACIA 
; ACIA_IRQ_SET = %10000000
ACIA_RDRF_BIT = %00001000     ; Receive Data Register Full
; ACIA_OVRN_BIT = %00000100     ; Overrun error
; ACIA_FE_BIT   = %00000010     ; Frame error
ACIA_TX_RDY_BIT = %00010000
ACIA_RX_RDY_BIT = %00001000

; LCD PANEL
LCD_CLS       = %00000001  ; Clear screen & reset display memory
LCD_TYPE      = %00111000  ; Set 8-bit mode; 2-line display; 5x8 font
LCD_MODE      = %00001100  ; Display on; cursor off; blink off
LCD_CURS_HOME = %00000010  ; return cursor to home position
LCD_CURS_L    = %00010000  ; shifts cursor to the left
LCD_CURS_R    = %00010100  ; shifts cursor to the right
LCD_EX = %10000000    ; Toggling this high enables execution of byte in register
LCD_RW = %01000000    ; Read/Write bit: 0 = read; 1 = write
LCD_RS = %00100000    ; Register select bit: 0 = instruction reg; 1 = data reg
LCD_BUSY_FLAG = %10000000 

; CPU 1             ; use 65C02 instruction set - maybe later

; --------- INITIALISATION -----------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start for the file, but...
ORG $C000         ; This is where the actual code starts.
.startcode
  sei             ; don't interrupt me yet
  cld             ; clear decimal flag - don't want to work in BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set
  txs             ; LSB as MSB is assumed to be $01

; SETUP VIA
  lda #%11111111  ; Set all pins on port B to output
  sta VIA_A_DDRB
  lda #%11100000  ; Set top 3 pins on port A to output
  sta VIA_A_DDRA

; SETUP ACIA
  lda #0
  sta ACIA_STAT_REG     ; reset ACIA
  sta UART_STATUS_REG   ; also zero-out our status register
  sta UART_RX_IDX       ; zero buffer index
  sta UART_TX_IDX       ; zero buffer index
  lda #UART_8N1_9600    ; set control register config - set speed & 8N1
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG     ; set command register config
  sta ACIA_CMD_REG

; SETUP LCD
  lda #LCD_TYPE   ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #LCD_MODE   ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #LCD_CLS    ; clear display, reset display memory
  jsr lcd_cmd

; ------------------------------------------------------------------------------
; ----     MAIN PROGRAM                                                     ----
; ------------------------------------------------------------------------------
.main

; Print initial message & prompt via serial
  lda #CHR_LINEEND          ; start with a couple of line feeds
  jsr serial_send_char
  jsr serial_send_char
  lda #<start_msg             ; LSB of message
  sta MSG_VEC
  lda #>start_msg             ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  jsr serial_send_lineend
  lda #<version_str           ; LSB of message
  sta MSG_VEC
  lda #>version_str           ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  jsr serial_send_prompt

; Print initial message on LCD
  lda #<start_msg             ; LSB of message
  sta MSG_VEC
  lda #>start_msg             ; MSB of message
  sta MSG_VEC+1
  jsr lcd_prt_msg

  ldx #0 : ldy #1             ; print version string on 2nd line of LCD
  jsr lcd_set_cursor
  lda #<version_str           ; LSB of message
  sta MSG_VEC
  lda #>version_str           ; MSB of message
  sta MSG_VEC+1
  jsr lcd_prt_msg

  lda #$f6                    ; just a test of the byte_to_hex_str subroutine
  jsr byte_to_hex_str
  lda #<TEXT_BUF
  sta MSG_VEC
  lda #>TEXT_BUF
  sta MSG_VEC+1
  jsr serial_send_msg

  jsr serial_send_prompt

  cli                     	  ; enable interrupts

; --------- MAIN LOOP ----------------------------------------------------------
.mainloop                   ; loop forever
  lda UART_STATUS_REG       ; load our serial status register
  and #UART_FL_RX_NUL_RCVD  ; is the 'null received' bit set?
  bne process_rx            ; if yes, process the buffer
  ldx UART_RX_IDX           ; load the value of the RX buffer index
  cpx #UART_RX_BUF_LEN      ; are we at the limit?
  bcs process_rx            ; branch if X >= UART_RX_BUF_LEN
; other tests may go here
  jmp mainloop              ; loop
.process_rx
  ; we're here because the null received bit is set or buffer is full
  ; jsr serial_print_rx_buf   ; print the buffer to the display
  ;jsr parse_rx_buffer
  jsr parse_input            ; puts command token in FUNC_RESULT
  lda FUNC_RESULT            ; just a test of the byte_to_hex_str subroutine
  jsr byte_to_hex_str
  lda #<TEXT_BUF
  sta MSG_VEC
  lda #>TEXT_BUF
  sta MSG_VEC+1
  jsr serial_send_msg
  jsr serial_send_prompt
  jmp mainloop              ; go around again

; ------------------------------------------------------------------------------
; ----     SUBROUTINES                                                      ----
; ------------------------------------------------------------------------------

INCLUDE "include/funcs_serial.asm"
INCLUDE "include/funcs_lcd.asm"
INCLUDE "include/funcs_text.asm"
INCLUDE "include/funcs_isr.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

; ---------DATA-----------------------------------------------------------------
ALIGN &100        ; start on new page

; COMMAND PARSING
; Inspired by keyword parsing in EhBASIC:
; https://github.com/Klaus2m5/6502_EhBASIC_V2.22/blob/master/patched/basic.asm
; (see line 8273 onward)
;
; Parsing routine will compare the first char of the command to the entries
; starting at cmd_ch1_tbl, using an offset counter to remember which one it's
; matching against. If we hit EOTBL_MKR, then matching has failed and we issue
; a syntax error.
; if it finds a match, it calculates the address for the next step using:
;    lookup_address = cmd_ptrs + (offset_counter * 2)
; 
; It then starts matching starting with the next char from lookup_addr.
; If it hits a token (ie, has value $80 or above) then it has matched. The
; token is the value we're seeking.
; The first time it doesn't match, it loops until it hits a token - incrementing
; the offset - & then starts again. If it hits EOCMD_SECTION then the match
; has failed and we issue a syntax error.

.cmd_ch1_tbl              ; table of command first characters
  equb "*"
  equb "L"
  equb "P"
  equb "V"
  equb EOTBL_MKR          ; end of table marker

.cmd_ptrs                 ; pointers to command table entries
  equw cmd_tbl_STAR       ; commands starting '*'
  equw cmd_tbl_ASCL       ; commands starting 'L'
  equw cmd_tbl_ASCP       ; commands starting 'P'
  equw cmd_tbl_ASCV       ; commands starting 'V'

; Command table
.cmd_tbl_STAR               ; commands starting '*'
.cmd_STAR
  equb CMD_TKN_STAR         ; not sure what I'm using this for yet
  equb EOCMD_SECTION        ; comes at end of each section
.cmd_tbl_ASCL               ; commands starting 'L'
.cmd_LM
  equs "M", CMD_TKN_LM      ; LM  
  equb EOCMD_SECTION
.cmd_tbl_ASCP               ; commands starting 'P'
.cmd_PRT
  equs "RT", CMD_TKN_PRT    ; PRT
  equb EOCMD_SECTION
.cmd_tbl_ASCV               ; commands starting 'V'
.cmd_VERS
  equs "ERBOSE", CMD_TKN_VERBOSE  ; VERBOSE
  equs "ERS", CMD_TKN_VERS        ; VERS
  equb EOCMD_SECTION

;---- SCRATCHPAD ---------------------------------------------------------------
.parse_input 
  lda #0                    ; a value of 0 for the token represents a failure
  sta FUNC_RESULT           ; we'll use this as the default
  lda UART_RX_BUF           ; load first char in buffer
  sta TEST_VAL              ; store it somewhere handy
  ldx #0                    ; offset counter
.parse_next_test
  lda cmd_ch1_tbl,X         ; get next char from table of cmd 1st chars
  cmp #EOTBL_MKR            ; is it the end of table marker?
  beq parse_1st_char_fail   ; if so, parsing has failed to find a match
  cmp TEST_VAL              ; otherwise compare against our input char
  beq parse_1st_char_match  ; if it matches, on to the next step
  inx                       ; otherwise, time to test next char in table
  jmp parse_next_test
.parse_1st_char_fail
  jmp parse_end
.parse_1st_char_match
  ; at this point, X holds the offset we need to look up an address in cmd_ptrs
  ; although we need to multiply it by 2
  stx TEST_VAL        ; tmp store x in handy location - repurposing TEST_VAL
  txa                 ; also put the value in A
  adc TEST_VAL        ; add the two together
  tax                 ; and put back in X
  lda <cmd_ptrs, X    ; get the relevant address from the cmd_ptrs table
  sta TBL_VEC         ; and put in TBL_VEC 
  lda >cmd_ptrs, X
  sta TBL_VEC+1
  ; we now have the start address for the relevant section of the command table
  ; in TBL_VEC and we've already matched on the first char
  ldy #0          ; offset for the command table
  ldx #1          ; offset for the input buffer, starting with 2nd char
.parse_next_chr
  lda UART_RX_BUF,X   ; get next char from buffer
  sta TEST_VAL        ; and put it somewhere handy - repurposing TEST_VAL again
  lda (TBL_VEC), Y    ; load the next test char from our command table
  cmp #$80            ; does it have a value $80 or more?
  bcs parse_token_found ; if >= $80, it's a token - success!
  cmp #EOCMD_SECTION  ; have we got to the end of the section without a match?
  beq parse_end       ; if so, we've failed, time to leave
  ; at this point, we've matched neither a token nor end of section marker.
  ; so it's time to test the buffer char itself - table char is still in A
  cmp TEST_VAL
  bne parse_next_cmd  ; if it's not equal, this isn't the right command
  inx                 ; otherwise, if it is equal, let's test the next buffer 
  iny                 ; char against the next command char
  jmp parse_next_chr
.parse_token_found
  sta FUNC_RESULT
  jmp parse_end
.parse_next_cmd
  ; that command didn't match, so let's spin ahead to the next one.
  ; X should stay the same, it's Y that needs to be incremented
.parse_next_cmd_chr
  iny                     ; increment offset
  lda (TBL_VEC), Y        ; load next char from cmd table
  cmp #$80                ; is it a token?
  bcs parse_next_cmd_jmp  ; if so, we're done
  jmp parse_next_cmd_chr  ; otherwise, loop
.parse_next_cmd_jmp
  iny                     ; one more for luck
  jmp parse_next_chr      ; now let's try again
.parse_end
  rts
;-------------------------------------------------------------------------------

.hex_chr_tbl                ; hex character table
  equs "0123456789ABCDEF"

.err_msg_syntax
  equs "What?", 0

.prompt_msg
  equs CHR_LINEEND, "Z>", 0

.start_msg
	equs "Zolatron 64", 0

.version_str
  equs "ROM v06-dev", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "bin/z64-ROM-06-dev.bin", startrom, endrom
