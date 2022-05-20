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
; minipro -p AT28C256 -w z64-ROM-<version>.bin

CPU 1                               ; use 65C02 instruction set

; COMMAND TOKENS
; These should be in alphabetical order. Where two or more commands share the
; same few chars at the start, the longer commands should come first.
; The order also has to be the same as that in data_tables.asm.
CMD_TKN_NUL  = $00                  ; This is what happens when you just hit RTN
CMD_TKN_FAIL = $01                  ; syntax error & whatnot
CMD_TKN_STAR = $80                  ; *
CMD_TKN_BRK  = CMD_TKN_STAR + 1
CMD_TKN_JMP  = CMD_TKN_BRK + 1
CMD_TKN_LM   = CMD_TKN_JMP + 1      ; LM - list memory
CMD_TKN_LP   = CMD_TKN_LM + 1       ; LP - list memory page
CMD_TKN_PEEK = CMD_TKN_LP + 1
CMD_TKN_POKE = CMD_TKN_PEEK + 1
CMD_TKN_PRT  = CMD_TKN_POKE + 1     ; PRT - print string to LCD
CMD_TKN_VERS = CMD_TKN_PRT + 1      ; VERS - show version

; ERROR CODES: must be in the same order as the error tables in data_tables.asm.
; Must also be sequential, starting at 1.
COMMAND_ERR_CODE      = 1
HEX_TO_BIN_ERR_CODE   = COMMAND_ERR_CODE+1
PARSE_ERR_CODE        = HEX_TO_BIN_ERR_CODE+1
READ_HEXBYTE_ERR_CODE = PARSE_ERR_CODE+1
SYNTAX_ERR_CODE       = READ_HEXBYTE_ERR_CODE+1

EOCMD_SECTION = 0                   ; end of section marker for command table
EOTBL_MKR     = 255                 ; end of table marker

CHR_LINEEND   = 10        ; ASCII code for line end - here we're using line feed
CHR_SPACE     = 32

EQUAL = 1
MORE_THAN = 2
LESS_THAN = 0

LED_BUSY = 1

ROMSTART = $C000

; Settings and address reservations for peripherals.
INCLUDE "include/cfg_uart_6551_acia.asm"
INCLUDE "include/cfg_uart_SC28L92.asm"
INCLUDE "include/cfg_via_2x16_lcd.asm"
;INCLUDE "include/cfg_via_ZolaDOS.asm"
INCLUDE "include/cfg_via_c.asm"

INCLUDE "include/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "include/cfg_page_2.asm"
; PAGE 3 is used as a serial TX buffer
; PAGE 4 is used as a serial RX buffer
INCLUDE "include/cfg_page_5.asm"

MACRO PRT_MSG msg_addr, func_addr
  lda #<msg_addr                              ; LSB of message
  sta MSG_VEC
  lda #>msg_addr                              ; MSB of message
  sta MSG_VEC+1
  jsr func_addr
ENDMACRO

MACRO LED_ON led_num
  pha : phx
  ldx #led_num
  lda led_on_mask,X
  ora VIAA_PORTA
  sta VIAA_PORTA
  plx : pla
ENDMACRO

MACRO LED_OFF led_num
  pha : phx
  ldx #led_num
  lda led_off_mask,X
  and VIAA_PORTA
  sta VIAA_PORTA
  plx : pla
ENDMACRO

MACRO LCD_SET_CTL ctl_bits        ; set control bits for LCD
  lda VIAA_PORTA                  ; load the current state or PORT A
  and #LED_MASK                   ; clear the top three bits
  ora #ctl_bits                   ; set those bits. Lower 5 bits should be 0s
  sta VIAA_PORTA                  ; store result
ENDMACRO

MACRO PRT_CHAR                   ; assumes character code is in A
  jsr acia_wait_send_clr
  sta ACIA_DATA_REG
ENDMACRO

; --------- INITIALISATION -----------------------------------------------------
ORG $8000         ; Using only the top 16KB of a 32KB EEPROM.
.startrom         ; This is where the ROM bytes start for the file, but...
ORG ROMSTART      ; This is where the actual code starts.
.startcode
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

; SETUP VIA A - LCD display
  lda #%11111111  
  sta VIAA_DDRB   ; Set all pins on port B to output - data for LCD
  sta VIAA_DDRA   ; Set all pins on port A to output - signals for LCD & LEDs

; SETUP VIA B - RPi interface
;  lda ZD_CTRL_PINDIR
;  sta ZD_CTRL_DDR

; SETUP VIA C - for experimentation
  lda #$FF
  sta VIAC_DDRA  ; set all pins as outputs
  sta VIAC_DDRB  ; set all pins as outputs

; SETUP ACIA
  stz UART_STATUS_REG
  jsr uart_6551_init
  jsr uart_SC28L92_init

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
  LED_ON 0
  LED_ON 1
  LED_ON 2
  LED_ON 3
  LED_ON 4

; Print initial message & prompt via serial
  lda #CHR_LINEEND                  ; start with a couple of line feeds
  PRT_CHAR
  PRT_CHAR
  PRT_MSG start_msg, stdout_println
  jsr stdout_prtlineend
  PRT_MSG version_str, stdout_println
  jsr stdout_prtprompt

  jsr lcd_clear_buf                 ; Clear LCD buffer
  PRT_MSG version_str, lcd_println  ; Print initial messages on LCD
  PRT_MSG start_msg, lcd_println
  
  lda #<250
  sta VIAA_TIMER_INTVL
  lda #>250
  sta VIAA_TIMER_INTVL+1

  lda #100                          ; x10ms = 1 sec
  sta VIAC_TIMER_INTVL
  stz VIAC_TIMER_INTVL+1

  jsr viac_init_timer

  stz BARLED_L                      ; zero-out barled display
  stz BARLED_H
  jsr barled_show
  
  jsr uart_SC28L92_test_msg
;  jsr delay
  LED_OFF 0
;  jsr delay
  LED_OFF 1
;  jsr delay
  LED_OFF 2
;  jsr delay
  LED_OFF 3
;  jsr delay
  LED_OFF 4

  cli                     	        ; enable interrupts

; --------- MAIN LOOP ----------------------------------------------------------
.mainloop                     ; loop forever
.main_chk_SC28L92
  lda UART_STATUS_REG         ; load our serial status register
  and #SC28L92_RXRDY_FL       ; AND with RX ready flag
  beq main_chk_acia           ; if this produced 0, on to next check
  LED_ON 1
;  jmp mainloop
  jmp main_service_SC28L92    ; otherwise go get data in SC28L92
.main_chk_acia
  lda UART_STATUS_REG
  and #STDIN_NUL_RCVD_FLG     ; is the 'null received' bit set?
  bne process_input           ; if yes, process the buffer
  ;clc                         ; is this necessary?  
  ldx STDIN_IDX               ; load the value of the RX buffer index
  cpx #STDIN_BUF_LEN          ; are we at the limit?
  bcs process_input           ; branch if X >= STDIN_BUF_LEN
; other tests may go here
.main_chk_viac
  jsr viac_chk_timer          ; result in FUNC_RESULT
  lda FUNC_RESULT
  cmp #LESS_THAN
  beq mainloop
  jsr barled_count
  jmp mainloop                ; loop

.main_service_SC28L92
  sei
  lda UART_STATUS_REG       ; we're here because the UART_STATUS_REG has the
  eor #SC28L92_RXRDY_FL     ; SC28L92_RXRDY_FL bit set - so unset it
  sta UART_STATUS_REG
  ldx STDIN_IDX             ; load the value of the buffer index
.main_service_SC28L92_loop
  lda SC28L92_RxFIFOA       ; load the byte in the data register into A
  sta STDIN_BUF,X           ; and store it in the buffer, at the offset
  beq main_service_SC28L92_set_null  ; if byte is the 0 terminator, go set the null flag
  cmp #CHR_LINEEND          ; or is it a line end?
  bne main_service_SC28L92_end  ; if not 0 or line end, go to next step
  stz STDIN_BUF,X			      ; if line end, replace with NULL
.main_service_SC28L92_set_null
  lda UART_STATUS_REG       ; load our status register
  ora #STDIN_NUL_RCVD_FLG   ; set the null byte received flag
  sta UART_STATUS_REG       ; re-save the status
.main_service_SC28L92_end
  inx                       ; increment the index for next time
  lda SC28L92_SRA           ; load status reg to see if there are any more bytes
  and #SC28L92_RxRDY        ; check RxRDY bit
  bne main_service_SC28L92_loop
  stx STDIN_IDX             ; save index
  cli
  jmp mainloop

.process_input
  \\ We're here because the null received bit is set or buffer is full
  ;sei
  LED_ON LED_BUSY
  lda UART_STATUS_REG         ; get our info register
  and #STDIN_CLEAR_FLAGS      ; zero all the RX flags
  sta UART_STATUS_REG         ; and re-save the register
  jsr parse_input             ; puts command token in FUNC_RESULT
  lda FUNC_RESULT             ; get the result
  cmp #CMD_TKN_NUL
  beq process_input_nul
  cmp #CMD_TKN_FAIL           ; this means a syntax error
  beq process_input_fail
  cmp #PARSE_ERR_CODE         ; this means a syntax error
  beq process_input_fail
  \\ anything other than CMD_TKN_NUL and CMD_TKN_FAIL should be a valid token
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
  lda #PARSE_ERR_CODE
  sta FUNC_ERR
  jsr print_error
.process_input_nul
  jsr stdout_prtprompt
  jmp process_input_done

\ ******************************************************************************
\ ***   COMMAND PROCESS FUNCTIONS                                            ***
\ ******************************************************************************

\-------------------------------------------------------------------------------
\ --- CMD: *                                                                 ---
\-------------------------------------------------------------------------------
.cmdprcSTAR
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: BRK                                                               ---
\-------------------------------------------------------------------------------
.cmdprcBRK
  lda STDIN_BUF,X         ; check there's nothing left in the RX buffer
  cmp #0                  ; should be null. Anything else is a mistake
  bne cmdprcBRK_fail
  ldx #$ff                ; reset stack pointer
  txs
  jmp ROMSTART            ; jump to start of ROM code
.cmdprcBRK_fail
  jmp cmdprc_fail

;-------------------------------------------------------------------------------
; --- CMD: JMP                                                                ---
;-------------------------------------------------------------------------------
.cmdprcJMP
  jsr read_hex_addr       ; puts bytes in FUNC_RES_L, FUNC_RES_H
  lda #0
  cmp FUNC_ERR
  bne cmdprcJMP_fail
  ldx #$ff                ; reset stack pointer
  txs
  jmp (FUNC_RES_L)
.cmdprcJMP_fail
  jmp cmdprc_fail 

\-------------------------------------------------------------------------------
\ --- CMD: LM  :  LIST MEMORY                                                ---
\-------------------------------------------------------------------------------
; Expects two, two-byte hex addresses and prints the memory contents in that 
; range. So the format is:
;     LM hhhh hhhh
; The first address must be lower than the second. The two addresses can be
; optionally separated by a space.
; Variables used: BYTE_CONV_L, TMP_OFFSET, TMP_COUNT, LOOP_COUNT, FUNC_RESULT
.cmdprcLM
  ; X currently contains the buffer index for the rest of the text in the RX 
  ; buffer (after the command), although the first char is likely to be a space.
  stz FUNC_ERR
; --- GET & CONVERT HEX VALUE PAIRS --------------------------------------------
; Get the two, 4-char addresses.
; The byte values are stored at the four locations starting at TMP_ADDR_A
; (which encompasses TMP_ADDR_A and TMP_ADDR_B).
  ldy #0
.cmdprcLM_next_addr         ; get next address from buffer
  jsr read_hex_addr         ; puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  cmp #0
  bne cmdprcLM_rd_addr_fail
  lda FUNC_RES_L            ; starts at 1. Toggles between 0 and 1 each time
  sta TMP_ADDR_A,Y
  iny                       ; inc Y to store the high byte
  lda FUNC_RES_H
  sta TMP_ADDR_A,Y
  cpy #3
  beq cmdprcLM_check
  iny
  jmp cmdprcLM_next_addr
.cmdprcLM_rd_addr_fail
  jmp cmdprc_fail
; --- CHECK VALUES: Check that values obtained are sane ------------------------
; The four bytes defining the memory range are in the four bytes starting
; at TMP_ADDR_A. The MSB of the start address must be less than or equal to
; the MSB of the end address. If it's less than, the LSB value doesn't matter.
; If it's equal, then the LSB of the start address must be less than that of
; the end address.
.cmdprcLM_check
  lda #0
  cmp FUNC_ERR
  bne cmdprcLM_chk_fail
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
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcLM_chk_nul           ; check there's nothing left in the RX buffer
  lda STDIN_BUF,X           ; should be null. Anything else is a mistake
  cmp #0
  bne cmdprcLM_chk_fail
  jsr display_memory
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: LP  : list memory page                                            ---
\-------------------------------------------------------------------------------
; Expects a two-character hex byte in the input buffer. It uses this as the
; high byte of an address and prints out the memory contents for that page (256
; bytes). EG: if you enter 'C0', it gives the memory contents for the range
; C000-C0FF.
.cmdprcLP
  jsr read_hex_byte         ; read 2 hex chars from input: result in FUNC_RESULT
  lda #0                    ; check for error
  cmp FUNC_ERR
  bne cmdprcLP_fail
.cmdprcLP_chk_nul           ; check there's nothing left in the RX buffer
  lda STDIN_BUF,X           ; should be null. Anything else is a mistake
  cmp #0
  bne cmdprcLP_input_fail
  lda FUNC_RESULT
  sta TMP_ADDR_A_H
  sta TMP_ADDR_B_H
  lda #$00
  sta TMP_ADDR_A_L
  lda #$FF 
  sta TMP_ADDR_B_L
  jsr display_memory
  jmp cmdprcLP_end
.cmdprcLP_input_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
.cmdprcLP_fail
  jmp cmdprc_fail
.cmdprcLP_end
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: PEEK  :  examine byte in memory                                   ---
\-------------------------------------------------------------------------------
.cmdprcPEEK
  jsr read_hex_addr         ; get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda #0
  cmp FUNC_ERR
  bne cmdprcPEEK_fail
  lda STDIN_BUF,X           ; check there's nothing left in the RX buffer
  cmp #0                    ; should be null. Anything else is a mistake
  bne cmdprcPEEK_fail
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; resulting string is in STR_BUF
  jsr stdout_prt_strbuf
  jmp cmdprcPEEK_end
.cmdprcPEEK_fail
  jmp cmdprc_fail
.cmdprcPEEK_end
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: POKE  :  set byte in memory                                       ---
\-------------------------------------------------------------------------------
.cmdprcPOKE
  jsr read_hex_addr         ; puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda #0
  cmp FUNC_ERR
  bne cmdprcPOKE_fail
  jsr read_hex_byte         ; get byte value - puts result in FUNC_RESULT
  lda #0
  cmp FUNC_ERR
  bne cmdprcPOKE_fail
  lda STDIN_BUF,X           ; check there's nothing left in the RX buffer
  cmp #0                    ; should be null. Anything else is a mistake
  bne cmdprcPOKE_fail
  lda FUNC_RESULT           ; store the byte in the given address
  ; --- debugging ----------------------
  ;jsr byte_to_hex_str
  ;jsr stdout_prt_strbuf
  ; ------------------------------------
  sta (FUNC_RES_L)
  jmp cmdprcPOKE_end
.cmdprcPOKE_fail
  jmp cmdprc_fail
.cmdprcPOKE_end
  jmp cmdprc_end
  
\-------------------------------------------------------------------------------
\ --- CMD: PRT  :  one day...                                                ---
\-------------------------------------------------------------------------------
.cmdprcPRT
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: VERS  : print firmware version to serial                          ---
\-------------------------------------------------------------------------------
.cmdprcVERS
  lda #<version_str             ; LSB of message
  sta MSG_VEC
  lda #>version_str             ; MSB of message
  sta MSG_VEC+1
  jsr stdout_println
  jmp cmdprc_end

.cmdprc_fail
  jsr print_error
.cmdprc_end
  jsr stdout_prtprompt

.process_input_done
;  jsr stdout_prtprompt
  stz STDIN_IDX                 ; reset RX buffer index
  ;cli                           ; turn interrupts back on
  LED_OFF LED_BUSY
  jmp mainloop                  ; go around again

INCLUDE "include/funcs_uart_6551_acia.asm"
INCLUDE "include/funcs_uart_SC28L92.asm"
INCLUDE "include/funcs_via_barled.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
;INCLUDE "include/funcs_math.asm"
INCLUDE "include/funcs_via_2x16_lcd.asm"
INCLUDE "include/data_tables.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

.version_str
  equs "ZolOS v.14b", 0
 
\-------------------------------------------------------------------------------
\ ---  TEST PROGRAM                                                          ---
\-------------------------------------------------------------------------------
; This is a place to try out test programs that are entirely separate from the
; main code. Run by using: JMP E000
ORG $E000
.testloop
  jmp testloop

ORG $FFFA
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "bin/z64-ROM-14.bin", startrom, endrom
