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
CMD_TKN_STAR = $80                  ; not sure what this is for yet
CMD_TKN_LM = CMD_TKN_STAR + 1       ; list memory
CMD_TKN_PRT = CMD_TKN_LM + 1        ; print string to LCD
CMD_TKN_VERBOSE = CMD_TKN_PRT +  1
CMD_TKN_VERS = CMD_TKN_VERBOSE + 1  ; show version

EOCMD_SECTION = 0              ; end of command section marker for command table
EOTBL_MKR = 255                ; end of table marker

INCLUDE "include/cfg_zero_page.asm"

TMP_TEXT_BUF = $07A0      ; general-purpose buffer/scratchpad
TMP_TEXT_BUF_SIZE = $40   ; 64 bytes

INCLUDE "include/cfg_acia.asm"

CHR_LINEEND   = 10  ; ASCII code for line end - here we're using line feed
CHR_SPACE     = 32
CHR_NUL       = 0

INCLUDE "include/cfg_via_lcd.asm"

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
  lda #<TMP_TEXT_BUF
  sta MSG_VEC
  lda #>TMP_TEXT_BUF
  sta MSG_VEC+1
  jsr serial_send_msg

  lda #'3'                  ; just a test of the hex_str_to_byte subroutine
  sta BYTE_CONV_H
  lda #'D'
  sta BYTE_CONV_L
  jsr hex_str_to_byte       ; result is in FUNC_RESULT
  lda FUNC_RESULT
  jsr serial_send_char      ; should appear as '='
  
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
  lda UART_STATUS_REG        ; get our info register
  and #UART_CLEAR_RX_FLAGS   ; zero all the RX flags
  sta UART_STATUS_REG        ; and re-save the register
  jsr parse_input            ; puts command token in FUNC_RESULT
  lda FUNC_RESULT            ; get the result so we can print it
  jsr byte_to_hex_str        ; puts string in TMP_TEXT_BUF buffer.
  lda #<TMP_TEXT_BUF
  sta MSG_VEC
  lda #>TMP_TEXT_BUF
  sta MSG_VEC+1
  jsr serial_send_msg
  jsr serial_send_prompt
  lda #0                     ; reset RX buffer index
  sta UART_RX_IDX            ; ** MIGHT WANT TO MOVE THIS ***
  jmp mainloop               ; go around again

INCLUDE "include/data_tables.asm"

INCLUDE "include/funcs_serial.asm"
INCLUDE "include/funcs_lcd.asm"
INCLUDE "include/funcs_text.asm"
INCLUDE "include/funcs_isr.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

;---- SCRATCHPAD ---------------------------------------------------------------

;-------------------------------------------------------------------------------

.version_str
  equs "ZolOS v06-dev", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "bin/z64-ROM-06-dev.bin", startrom, endrom
