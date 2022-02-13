; ROM code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i z64-main.asm
;
; Write to EEPROM with:
; minipro -p AT28C256 -w z64-ROM-dev.bin

CPU 1                               ; use 65C02 instruction set

; COMMAND TOKENS
; These should be in alphabetical order. Where two or more commands share the
; same few chars at the start, the longer commands should come first.
CMD_TKN_NUL = $00                   ; This is what happens when you just hit RTN
CMD_TKN_FAIL = $01                  ; syntax error & whatnot
CMD_TKN_STAR = $80                  ; *
CMD_TKN_LM = CMD_TKN_STAR + 1       ; LM - list memory
CMD_TKN_LP = CMD_TKN_LM + 1         ; LP - list memory page
CMD_TKN_PRT = CMD_TKN_LP + 1        ; PRT - print string to LCD
CMD_TKN_VERS = CMD_TKN_PRT + 1      ; VERS - show version

; ERROR CODES
READ_HEXBYTE_ERR    = $E0
READ_ADDR_ERR       = $E1
HEX_TO_BIN_ERR_CODE = $EE

EOCMD_SECTION = 0                   ; end of section marker for command table
EOTBL_MKR = 255                     ; end of table marker

CHR_LINEEND   = 10  ; ASCII code for line end - here we're using line feed
CHR_SPACE     = 32

INCLUDE "include/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "include/cfg_page_2.asm"
; PAGE 3 is used as a serial TX buffer
; PAGE 4 is used as a serial RX buffer
INCLUDE "include/cfg_page_5.asm"

; Settings and address reservations for serial.
INCLUDE "include/cfg_acia.asm"
INCLUDE "include/cfg_via_lcd.asm"


; --------- INITIALISATION -----------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start for the file, but...
ORG $C000         ; This is where the actual code starts.
.startcode
  sei             ; don't interrupt me yet
  cld             ; clear decimal flag - don't want to work in BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set
  txs             ; LSB, as MSB is assumed to be $01

; SETUP VIA A
  lda #%11111111  ; Set all pins on port B to output - data for LCD
  sta VIA_A_DDRB
  lda #%11100000  ; Set top 3 pins on port A to output - signals for LCD
  sta VIA_A_DDRA

; SETUP ACIA
  stz ACIA_STAT_REG     ; reset ACIA
  stz UART_STATUS_REG   ; also zero-out our status register
  stz UART_RX_IDX       ; zero buffer index
  stz UART_TX_IDX       ; zero buffer index
  stz PROC_REG          ; initialised process register
  lda #UART_8N1_9600    ; set control register config - set speed & 8N1
  sta ACIA_CTRL_REG
  lda #ACIA_CMD_CFG     ; set command register config
  sta ACIA_CMD_REG

; SETUP LCD
  lda #LCD_TYPE         ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #LCD_MODE         ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #LCD_CLS          ; clear display, reset display memory
  jsr lcd_cmd

; ------------------------------------------------------------------------------
; ----     MAIN PROGRAM                                                     ----
; ------------------------------------------------------------------------------
.main

; Print initial message & prompt via serial
  lda #CHR_LINEEND            ; start with a couple of line feeds
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
.mainloop                     ; loop forever
  lda UART_STATUS_REG         ; load our serial status register
  and #UART_FL_RX_NUL_RCVD    ; is the 'null received' bit set?
  bne process_rx              ; if yes, process the buffer
  clc                         ; is this necessary?  
  ldx UART_RX_IDX             ; load the value of the RX buffer index
  cpx #UART_RX_BUF_LEN        ; are we at the limit?
  bcs process_rx              ; branch if X >= UART_RX_BUF_LEN
; other tests may go here
  jmp mainloop                ; loop

.process_rx
  ; we're here because the null received bit is set or buffer is full
  sei
  lda UART_STATUS_REG         ; get our info register
  and #UART_CLEAR_RX_FLAGS    ; zero all the RX flags
  sta UART_STATUS_REG         ; and re-save the register
  jsr parse_input             ; puts command token in FUNC_RESULT
  lda FUNC_RESULT             ; get the result

  cmp #CMD_TKN_NUL
  beq process_input_nul

  cmp #CMD_TKN_FAIL           ; this means a syntax error
  beq process_input_fail
  ; anything other than CMD_TKN_NUL and CMD_TKN_FAIL should be a valid cmd token
  sec
  sbc #$80                    ; this turns the token into an offset for our
  asl A                       ; cmdprcptrs table, once it's multiplied by 2
  tay                         ; transfer to Y to use as an offset
  lda cmdprcptrs,Y            ; load LSB of pointer
  sta TBL_VEC_L               ; and store in our table vector
  lda cmdprcptrs+1,Y          ; load MSB of pointer
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
.cmdprcptrs                 ; these entries need to be in the same order as
  equw cmdprcSTAR           ; the CMD_TKN_* definitions
  equw cmdprcLM             ; LM - list memory
  equw cmdprcLP             ; LP - list page
  equw cmdprcPRT
  equw cmdprcVERS           ; VERS - version

; ******************************************************************************
; ***   COMMAND PROCESS FUNCTIONS                                            ***
; ******************************************************************************

;-------------------------------------------------------------------------------
; --- CMD: *                                                                 ---
;-------------------------------------------------------------------------------
.cmdprcSTAR
  jmp cmdprc_end

;-------------------------------------------------------------------------------
; --- CMD: LM  :  LIST MEMORY                                                ---
;-------------------------------------------------------------------------------
.cmdprcLM
  ; LM should be followed by 2 16-bit addresses in hex, optionally separated by 
  ; a space.
  ; That's a total of eight ASCII chars in the buffer, which we need to read
  ; as pairs of characters which will be converted to their numeric equivalents.
  ; As the addresses will be written as big-endian, we also need to convert to
  ; little-endian format.
  ; X currently contains the BUF_PTR for the rest of the text in the RX buffer
  ; (after the command), although the first char is likely to be a space.
  ;stz TMP_COUNT             ; keep track of how many PAIRS of bytes we've read
  ;stz LOOP_COUNT            ; & how many times through the loop
  stz FUNC_ERR
  ;lda #0                    ; offset for TMP_ADDR_A
  ;sta TMP_OFFSET            ; - needs to be 0 then 2
  ;ldx BUF_PTR              ; not really needed
  ;stz FUNC_RESULT
; --- GET & CONVERT HEX VALUE PAIRS --------------------------------------------
; Get the two, 4-char addresses.
; The byte values are stored at the four locations starting at TMP_ADDR_A
; (which encompasses TMP_ADDR_A and TMP_ADDR_B).
; Variables used: BYTE_CONV_L, TMP_OFFSET, TMP_COUNT, LOOP_COUNT, FUNC_RESULT
  ldy #0
.cmdprcLM_next_addr         ; get next address from buffer
  jsr read_hex_addr         ; puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_RES_L            ; starts at 1. Toggles between 0 and 1 each time
  sta TMP_ADDR_A,Y
  iny
  lda FUNC_RES_H
  sta TMP_ADDR_A,Y
  cpy #3
  beq cmdprcLM_check
  iny
  jmp cmdprcLM_next_addr



; --- CHECK VALUES: Check that values obtained are sane ------------------------
; The four bytes defining the memory range are in the four bytes starting
; at TMP_ADDR_A. The MSB of the start address must be less than or equal to
; the MSB of the end address. If it's less than, the LSB value doesn't matter.
; If it's equal, then the LSB of the start address must be less than that of
; the end address.
.cmdprcLM_check
  lda TMP_ADDR_B_H          ; MSB of end address
  cmp TMP_ADDR_A_H          ; MSB of start address
  beq cmdprcLM_chk_lsb      ; they're equal, so now check LSB
  bcc cmdprcLM_chk_fail     ; start is more than end
  jmp cmdprcLM_chk_nul
.cmdprcLM_chk_lsb
  lda TMP_ADDR_B_L          ; LSB of end address
  cmp TMP_ADDR_A_L          ; LSB of start address
  beq cmdprcLM_chk_fail     ; if equal, then both addresses are same - an error
  bcs cmdprcLM_chk_nul
.cmdprcLM_chk_fail
  jmp cmdprc_fail
.cmdprcLM_chk_nul           ; check there's nothing left in the RX buffer
  lda UART_RX_BUF,X         ; should be null. Anything else is a mistake
  cmp #0
  bne cmdprcLM_chk_fail
  jsr display_memory
  jmp cmdprc_end

; ------------------------------------------------------------------------------
; --- DISPLAY MEMORY                                                         ---
; ------------------------------------------------------------------------------
.display_memory
; The start and end addresses must be stored at TMP_ADDR_A and TMP_ADDR_B.
; We'll leave TMP_ADDR_B alone, but increment TMP_ADDR_B until the two match.

; --- TEMP ROUTINE : print reversed (little-endian) numbers to serial ----------
ldy #0
.cmdprcLM_tmp
  lda TMP_ADDR_A,Y 
  jsr byte_to_hex_str        ; string version now in STR_BUF
  lda #<STR_BUF              ; LSB of message
  sta MSG_VEC
  lda #>STR_BUF              ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  lda #$20  
  jsr serial_send_char
  cpy #3
  beq cmdprcLM_tmp_end
  iny
  jmp cmdprcLM_tmp
.cmdprcLM_tmp_end
  lda #CHR_LINEEND
  jsr serial_send_char
; --- END OF TEMP SECTION ------------------------------------------------------

  stz TMP_COUNT                 ; keep track how many bytes printed in each row
.display_mem_next_line
  lda TMP_ADDR_A_L             ; load the value of the byte at addr
  sta FUNC_RES_L           ; puts ASCII string in STR_BUF
  lda TMP_ADDR_A_H
  sta FUNC_RES_H           ; puts ASCII string in STR_BUF
  jsr res_word_to_hex_str ; creates ASCII hex string starting at STR_BUF
  lda #$20
  sta STR_BUF + 4
  stz STR_BUF + 5
  jsr serial_send_str_buf

.display_mem_next_addr
  ldx #0
  lda (TMP_ADDR_A)              ; load the value of the byte at addr
  jsr byte_to_hex_str           ; puts ASCII string in STR_BUF
  lda STR_BUF                   ; transferring STR_BUF to UART buffer
  sta UART_TX_BUF,X             ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda STR_BUF+1                 ;     "           "     "   "
  sta UART_TX_BUF,X             ;     "           "     "   "
  inx                           ;     "           "     "   "
  lda #$20                      ; followed by a space
  sta UART_TX_BUF,X
  inx
  stz UART_TX_BUF,X             ; followed by null terminator
  jsr serial_send_buffer
  inc TMP_COUNT
  lda TMP_COUNT
  cmp #$10                      ; have we got to 16?
  beq display_mem_endline
  jmp display_mem_chk_MSB
.display_mem_endline      ; start a new line of output
  lda #CHR_LINEEND
  jsr serial_send_char
  stz TMP_COUNT                 ; reset to 0 for next line
.display_mem_chk_MSB
  lda TMP_ADDR_A_H              ; compare the MSBs of the addresses
  cmp TMP_ADDR_B_H
  beq display_mem_chk_LSB          ; if equal, go on to check LSBs
  jmp display_mem_inc_LSB          ; otherwise, go get the next byte from memory
.display_mem_chk_LSB
  lda TMP_ADDR_A_L              ; compare the LSBs
  cmp TMP_ADDR_B_L
  beq display_mem_output_end       ; if they're also equal, we're done
.display_mem_inc_LSB
  inc TMP_ADDR_A_L              ; increment LSB of start address
  lda TMP_ADDR_A_L
  cmp #$00                      ; has it rolled over?
  bne display_mem_loopback     ; if not, go get next byte
  inc TMP_ADDR_A_H              ; if it has rolled over, increment MSB
.display_mem_loopback
  lda TMP_COUNT
  cmp #$00
  beq display_mem_next_line
  jmp display_mem_next_addr
.display_mem_output_end
  lda #CHR_LINEEND
  jsr serial_send_char
  jmp display_mem_end
; ------------------------------------------------------------------------------
.display_mem_fail
  jsr cmd_proc_err_msg
.display_mem_end
  rts

;-------------------------------------------------------------------------------
; --- CMD: LP  : list memory page                                            ---
;-------------------------------------------------------------------------------
.cmdprcLP
  jsr read_hex_byte         ; read 2 hex chars from input: result in FUNC_RESULT
  lda #0                    ; check for error
  cmp FUNC_ERR
  bne cmdprcLP_fail
  lda FUNC_RESULT
  sta TMP_ADDR_A_H
  sta TMP_ADDR_B_H
  lda #$00
  sta TMP_ADDR_A_L
  lda #$FF 
  sta TMP_ADDR_B_L
  jsr display_memory
  jmp cmdprcLP_end
.cmdprcLP_fail
  jsr cmd_proc_err_msg
.cmdprcLP_end
  jmp cmdprc_end
;-------------------------------------------------------------------------------
; --- CMD: PRT  :                                                            ---
;-------------------------------------------------------------------------------
.cmdprcPRT
  jmp cmdprc_end
;-------------------------------------------------------------------------------
; --- CMD: VERS  : print firmware version to serial                          ---
;-------------------------------------------------------------------------------
.cmdprcVERS
  lda #<version_str             ; LSB of message
  sta MSG_VEC
  lda #>version_str             ; MSB of message
  sta MSG_VEC+1
  jsr serial_send_msg
  jmp cmdprc_end

.cmdprc_fail
  jsr cmd_proc_err_msg
.cmdprc_end
  jsr serial_send_prompt

.process_rx_done
;  jsr serial_send_prompt
  stz UART_RX_IDX               ; reset RX buffer index
  cli
  jmp mainloop                  ; go around again

;INCLUDE "include/cmd_proc.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
INCLUDE "include/funcs_lcd.asm"
INCLUDE "include/funcs_math.asm"
INCLUDE "include/funcs_serial.asm"
INCLUDE "include/funcs_text.asm"
INCLUDE "include/data_tables.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

.version_str
  equs "ZolOS v.10", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "bin/z64-ROM-dev.bin", startrom, endrom
