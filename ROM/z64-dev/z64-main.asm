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
CMD_TKN_NUL = $00                   ; This is what happens when you just hit RTN
CMD_TKN_FAIL = $01                  ; syntax error & whatnot
CMD_TKN_STAR = $80                  ; not sure what this is for yet
CMD_TKN_LM = CMD_TKN_STAR + 1       ; list memory
CMD_TKN_PRT = CMD_TKN_LM + 1        ; print string to LCD
CMD_TKN_VERBOSE = CMD_TKN_PRT +  1
CMD_TKN_VERS = CMD_TKN_VERBOSE + 1  ; show version

EOCMD_SECTION = 0              ; end of command section marker for command table
EOTBL_MKR = 255                ; end of table marker

INCLUDE "include/cfg_zero_page.asm"

TMP_BUF = $07A0      ; general-purpose buffer/scratchpad
TMP_BUF_SIZE = $40   ; 64 bytes
TMP_IDX = TMP_BUF + TMP_BUF_SIZE + 1
TMP_OFFSET = TMP_IDX + 1
TMP_COUNT = TMP_OFFSET + 1
TMP_CHR = TMP_COUNT + 1
STR_BUF = TMP_CHR + 1
STR_BUF_SZ = $80    ; 128 bytes
LOOP_COUNT = STR_BUF + STR_BUF_SZ + 1

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
  
  cli                     	  ; enable interrupts

; --------- MAIN LOOP ----------------------------------------------------------
.mainloop                   ; loop forever
  lda UART_STATUS_REG       ; load our serial status register
  and #UART_FL_RX_NUL_RCVD  ; is the 'null received' bit set?
  bne process_rx            ; if yes, process the buffer
  clc
  ldx UART_RX_IDX           ; load the value of the RX buffer index
  cpx #UART_RX_BUF_LEN      ; are we at the limit?
  bcs process_rx            ; branch if X >= UART_RX_BUF_LEN
; other tests may go here
  jmp mainloop              ; loop
.process_rx
  ; we're here because the null received bit is set or buffer is full
  sei
  lda UART_STATUS_REG        ; get our info register
  and #UART_CLEAR_RX_FLAGS   ; zero all the RX flags
  sta UART_STATUS_REG        ; and re-save the register
  jsr parse_input            ; puts command token in FUNC_RESULT
  lda FUNC_RESULT            ; get the result

  cmp #CMD_TKN_NUL
  beq process_input_nul

  cmp #CMD_TKN_FAIL          ; this means a syntax error
  beq process_input_fail
  ; anything other than CMD_TKN_NUL and CMD_TKN_FAIL should be a valid cmd token
  sec
  sbc #$80                    ; this turns the token into an offset for our
  asl A                       ; cmd_proc_ptrs table, once it's multiplied by 2
  tay                         ; transfor to Y to use as an offset
  lda cmd_proc_ptrs,Y         ; load LSB of pointer
  sta TBL_VEC_L               ; and store in our table vector
  lda cmd_proc_ptrs+1,Y       ; load MSB of pointer
  sta TBL_VEC_H               ; also store in table vector
  jmp (TBL_VEC_L)             ; now jump to location indicated by pointer

.process_input_fail
  lda #<err_msg_syntax        ; LSB of message
  sta MSG_VEC
  lda #>err_msg_syntax        ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
.process_input_nul
  jsr serial_send_prompt
  jmp process_rx_done

; COMMAND POINTER JUMP TABLE
.cmd_proc_ptrs               ; these entries need to be in the same order as
  equw cmd_proc_STAR         ; the CMD_TKN_* definitions
  equw cmd_proc_LM
  equw cmd_proc_PRT
  equw cmd_proc_VERBOSE
  equw cmd_proc_VERS

; COMMAND PROCESS TABLE
.cmd_proc_STAR
  jmp cmd_proc_end

; ----- WORK IN PROGRESS -------------------------------------------------------
.cmd_proc_LM                ; list memory
  ; should be followed by 2 addresses, optionally separated by a space.
  ; That's a total of eight ASCII bytes in the buffer, which we need to read
  ; as pairs of characters which will be converted to their numeric equivalents.
  ; As the addresses will be written as big-endian, we also need to convert to
  ; little-endian format.
  ; X currently contains the BUF_PTR for the rest of the text in the RX buffer
  ; (after the command), although the first char is likely to be a space.
  lda #0                    
  sta TMP_COUNT             ; keep track of how many PAIRS of bytes we've read
  sta LOOP_COUNT            ; & how many times through the loop
  lda #1                    ; offset for LSB/MSB, to reverse order of bytes
  sta TMP_OFFSET            ; - needs to be 1 then 0 for each pair
.cmd_proc_LM_next2          ; get next pair of chars from buffer
  ldy #1                    ; offset for where we're storing each byte from buf
.cmd_proc_LM_next_byte
  lda UART_RX_BUF,X         ; get next byte from serial buffer
  ; somewhere in here we should probably check that these incoming chars
  ; are in the range 0-9 A-F
  inx                       ; increment for next time
  cmp #0                    ; is the buffer char a null? Shouldn't be
  beq cmd_proc_LM_fail      ; - that's an error
  cmp #$20                  ; if it's a space, ignore it & get next byte
  beq cmd_proc_LM_next_byte
  sta BYTE_CONV_L,Y         ; store in BYTE_CONV buffer, high byte first
  cpy #0                    ; if 0, we've now got the second of the 2 bytes
  beq cmd_proc_LM_conv
  dey                       ; otherwise go get low byte
  jmp cmd_proc_LM_next_byte
.cmd_proc_LM_conv           ; convert character pair to int byte value
  ; we've got our pair of bytes in BYTE_CONV_L and BYTE_CONV_L+1
  jsr hex_str_to_byte       ; convert them - result is in FUNC_RESULT
  ; calculate offset for where want want to store this byte
  ; it will be TMP_OFFSET + TMP_COUNT
  lda TMP_OFFSET            ; starts at 1. Toggles between 0 and 1 each time
  clc
  adc TMP_COUNT             ; is 0 for first two passes, then 2 for second two
  tay                       ; transfer to Y to use as offset
  lda FUNC_RESULT           ; load the result from the previous conversion
  sta TMP_BUF,Y             ; store in buffer, with offset
  ; update counters
  lda TMP_OFFSET            ; toggle between 0 & 1. Do this by EORing with 1
  eor #1 
  sta TMP_OFFSET
  inc LOOP_COUNT            ; update counter
  lda LOOP_COUNT            ; TMP_COUNT needs to be 0 when LOOP_COUNT is 0
  and #%00000010            ; or 1, and 2 when LOOP_COUNT is 2 or 3. Do this
  sta TMP_COUNT             ; by ANDing with 2.
  lda #4
  cmp LOOP_COUNT
  beq cmd_proc_LM_output
  jmp cmd_proc_LM_next2
.cmd_proc_LM_output
  ; check that there's nothing left in the RX buffer
  lda UART_RX_BUF,X         ; should be null. Anything else is a mistake
  cmp #0
  beq cmd_proc_LM_o_ok
  jmp cmd_proc_LM_fail



.cmd_proc_LM_o_ok
  ldy #0
.cmd_proc_LM_o_next
  lda TMP_BUF,Y 
  sta TMP_CHR
  jsr byte_to_hex_str       ; string version now in STR_BUF
  lda #<STR_BUF             ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF             ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  lda #$20  
  jsr serial_send_char
  cpy #3
  beq cmd_proc_LM_o_end
  iny
  jmp cmd_proc_LM_o_next
.cmd_proc_LM_o_end
  lda #10
  jsr serial_send_char
  jmp cmd_proc_LM_end
.cmd_proc_LM_chk
  ; subtract one number from the other to check we have sensible numbers
  ; see: https://retro64.altervista.org/blog/an-introduction-to-6502-math-addiction-subtraction-and-more/


.cmd_proc_LM_fail
  lda #<err_msg_cmd             ; LSB of message
  sta MSG_VEC
  lda #>err_msg_cmd             ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
.cmd_proc_LM_end
  jmp cmd_proc_end
; ------------------------------------------------------------------------------
.cmd_proc_PRT
  jmp cmd_proc_end
.cmd_proc_VERBOSE
  jmp cmd_proc_end
.cmd_proc_VERS              ; print firmware version to serial
  lda #<version_str         ; LSB of message
  sta MSG_VEC
  lda #>version_str         ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
.cmd_proc_end
  jsr serial_send_prompt
.process_rx_done
;  jsr byte_to_hex_str        ; puts string in TMP_TEXT_BUF buffer.
;  lda #<TMP_TEXT_BUF
;  sta MSG_VEC
;  lda #>TMP_TEXT_BUF
;  sta MSG_VEC+1
;  jsr serial_send_msg
;  jsr serial_send_prompt
  lda #0                     ; reset RX buffer index
  sta UART_RX_IDX            ; ** MIGHT WANT TO MOVE THIS ***
  cli
  jmp mainloop               ; go around again

;INCLUDE "include/cmd_proc.asm"
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
  equs "ZolOS dev", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "../bin/z64-ROM-dev.bin", startrom, endrom
