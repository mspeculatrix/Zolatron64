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
<<<<<<< HEAD
; minipro -p AT28C256 -w z64-ROM-<version>.bin

CPU 1                                             ; Use 65C02 instruction set

INCLUDE "../LIB/cfg_main.asm"
INCLUDE "../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../LIB/cfg_page_2.asm"                   ; OS Indirection Table
; PAGE 3 is used for I/O buffers, plus indexes, defined in cfg_main.asm
INCLUDE "../LIB/cfg_page_4.asm"                   ; Misc buffers etc
; PAGE 5 is reserved for user program workspace
; PAGES 6 & 7 not currently used - maybe ZolaDOS workspace

INCLUDE "include/cfg_ROM.asm"
INCLUDE "include/cfg_uart_6551_acia.asm"
;INCLUDE "include/cfg_uart_SC28L92.asm"
INCLUDE "../LIB/cfg_VIAA.asm"
INCLUDE "../LIB/cfg_2x16_lcd.asm"
INCLUDE "include/cfg_VIAB_ZolaDOS.asm"
INCLUDE "../LIB/cfg_VIAC.asm"

; --------- INITIALISATION -----------------------------------------------------
ORG $8000             ; Using only the top 16KB of a 32KB EEPROM.
.startrom             ; This is where the ROM bytes start for the file, but...
ORG ROMSTART          ; This is where the actual code starts.
.startcode
  sei                 ; Don't interrupt me yet
  cld                 ; We don' need no steenkin' BCD
  ldx #$ff            ; Set stack pointer to $01FF - only need to set
  txs                 ; the LSB, as MSB is assumed to be $01

  stz TIMER_STATUS_REG

; SETUP OS CALL VECTORS
  lda #<read_hex_byte       ; OSRDHBYTE
  sta OSRDHBYTE_VEC
  lda #>read_hex_byte
  sta OSRDHBYTE_VEC + 1
  lda #<read_hex_addr       ; OSRDHADDR
  sta OSRDHADDR_VEC
  lda #>read_hex_addr
  sta OSRDHADDR_VEC + 1
  lda #<read_filename       ; OSRDFNAME
  sta OSRDFNAME_VEC
  lda #>read_filename
  sta OSRDFNAME_VEC + 1
  lda #<acia_sendbuf        ; OSWRBUF
  sta OSWRBUF_VEC
  lda #>acia_sendbuf
  sta OSWRBUF_VEC + 1
  lda #<acia_writechar      ; OSWRCH
  sta OSWRCH_VEC
  lda #>acia_writechar
  sta OSWRCH_VEC + 1
  lda #<os_print_error      ; OSWRERR
  sta OSWRERR_VEC
  lda #>os_print_error
  sta OSWRERR_VEC + 1
  lda #<acia_println        ; OSWRMSG
  sta OSWRMSG_VEC
  lda #>acia_println
  sta OSWRMSG_VEC + 1
  lda #<acia_prt_strbuf     ; OSWRSBUF
  sta OSWRSBUF_VEC
  lda #>acia_prt_strbuf
  sta OSWRSBUF_VEC + 1

  lda #<byte_to_hex_str     ; OSB2HEX
  sta OSB2HEX_VEC
  lda #>byte_to_hex_str
  sta OSB2HEX_VEC + 1
  lda #<hex_str_to_byte     ; OSHEX2B
  sta OSHEX2B_VEC
  lda #>hex_str_to_byte
  sta OSHEX2B_VEC + 1

  lda #<lcd_prt_chr         ; OSLCDCH
  sta OSLCDCH_VEC
  lda #>lcd_prt_chr
  sta OSLCDCH_VEC + 1
  lda #<lcd_cls             ; OSLCDCLS
  sta OSLCDCLS_VEC
  lda #>lcd_cls
  sta OSLCDCLS_VEC + 1
  lda #<lcd_prt_err         ; OSLCDERR
  sta OSLCDERR_VEC
  lda #>lcd_prt_err
  sta OSLCDERR_VEC + 1
  lda #<lcd_println         ; OSLCDMSG
  sta OSLCDMSG_VEC
  lda #>lcd_println
  sta OSLCDMSG_VEC + 1
  lda #<lcd_print_byte      ; OSLCDPRB
  sta OSLCDPRB
  lda #>lcd_print_byte
  sta OSLCDPRB + 1
  lda #<lcd_set_cursor      ; OSLCDSC 
  sta OSLCDSC_VEC
  lda #>lcd_set_cursor
  sta OSLCDSC_VEC + 1

; Initialise registers
  stz STDIN_STATUS_REG

; Select serial as default input/output streams
  lda #STR_SEL_SERIAL
  sta STREAM_SELECT_REG

; SETUP VIA A - LCD display & LEDs
  lda #%11111111  
  sta VIAA_DDRB   ; Set all pins on port B to output - data for LCD
  sta VIAA_DDRA   ; Set all pins on port A to output - signals for LCD & LEDs

; SETUP VIA B - ZolaDOS RPi interface
  jsr zd_init

; SETUP VIA C - for experimentation
  lda #$FF
  sta VIAC_DDRA  ; set all pins as outputs
  sta VIAC_DDRB  ; set all pins as outputs

; SETUP ACIA
  jsr uart_6551_init
;  jsr uart_SC28L92_init
=======
; minipro -p AT28C256 -w z64-ROM-dev.bin

CPU 1                               ; use 65C02 instruction set

; COMMAND TOKENS
; These should be in alphabetical order. Where two or more commands share the
; same few chars at the start, the longer commands should come first.
; The order also has to be the same as that in data_tables.asm.
CMD_TKN_NUL = $00                   ; This is what happens when you just hit RTN
CMD_TKN_FAIL = $01                  ; syntax error & whatnot
CMD_TKN_STAR = $80                  ; *
CMD_TKN_LM = CMD_TKN_STAR + 1       ; LM - list memory
CMD_TKN_LP = CMD_TKN_LM + 1         ; LP - list memory page
CMD_TKN_PRT = CMD_TKN_LP + 1        ; PRT - print string to LCD
CMD_TKN_VERS = CMD_TKN_PRT + 1      ; VERS - show version

; ERROR CODES: must be in the same order as the error tables in data_tables.asm.
; Must also be sequential, starting at 1.
COMMAND_ERR_CODE      = 1
HEX_TO_BIN_ERR_CODE   = COMMAND_ERR_CODE+1
PARSE_ERR_CODE        = HEX_TO_BIN_ERR_CODE+1
READ_HEXBYTE_ERR_CODE = PARSE_ERR_CODE+1
SYNTAX_ERR_CODE       = READ_HEXBYTE_ERR_CODE+1

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

; Settings and address reservations for peripherals.
INCLUDE "include/cfg_6551_acia.asm"
INCLUDE "include/cfg_via_2x16_lcd.asm"


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
>>>>>>> e853aa37500bdedde611b732996f55e234f8d23a

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
<<<<<<< HEAD
  LED_ON 0
  LED_ON 1
  LED_ON 2
  LED_ON 3
  LED_ON 4

; Print initial message & prompt via serial
  lda #CHR_LINEEND                  ; start with a couple of line feeds
  jsr OSWRCH
  jsr OSWRCH
  PRT_MSG start_msg, acia_println
  lda #CHR_LINEEND
  jsr OSWRCH
  PRT_MSG version_str, acia_println

  jsr lcd_clear_buf                 ; Clear LCD buffer
  PRT_MSG version_str, lcd_println  ; Print initial messages on LCD
  PRT_MSG start_msg, lcd_println
  
  lda #<500                         ; interval for delay function - in ms
  sta VIAA_TIMER_INTVL
  lda #>500
  sta VIAA_TIMER_INTVL+1
  
;  jsr uart_SC28L92_test_msg
  jsr delay
  LED_OFF 0
  jsr delay
  LED_OFF 1
  jsr delay
  LED_OFF 2
  jsr delay
  LED_OFF 3
  jsr delay
  LED_OFF 4

  cli                     	        ; enable interrupts

.soft_reset
  jsr acia_prtprompt

; --------- MAIN LOOP ----------------------------------------------------------
.mainloop                           ; loop forever
.main_chk_stdin
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG               ; Is the 'null received' bit set?
  bne process_input                     ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs process_input                     ; Branch if X >= STR_BUF_LEN
;.main_chk_SC28L92
;  lda STDIN_STATUS_REG            ; load our serial status register
;  and #DUART_RxA_BUF_FULL_FL
;  bne main_service_SC28L92
;  and DUART_RxA_NUL_RCVD_FL
;  bne main_service_SC28L92
;  jmp main_chk_viac           ; if this produced 0, on to next check
;.main_chk_viac
;  jsr viac_chk_timer                    ; Result in FUNC_RESULT
;  lda FUNC_RESULT
;  cmp #LESS_THAN
;  beq mainloop
;  jsr barled_count
  jmp mainloop                          ; Loop

.process_input
  \\ We're here because the null received bit is set or STDIN_BUF full
  ; **** NEED TO REWORK THIS ****
  ; Does this need to be an OS process, so that user programs can access it?
  ; WHAT IS THE PURPOSE OF THIS ROUTINE?
  ; Currently, it parses for commands. But is that necessarily what we want it
  ; to do in a user program context?
  ; Maybe we could update it so that it parses the first word (up to a space or
  ; nul) and then places that word in its own buffer. And it transfers the rest
  ; of the input buffer (minus any leading spaces) into another buffer.
  ; We could possibly specify the locations of those buffers throug indirection
  ; so that user programs could set up their own buffers.
  ; We would then need some sort of context switch - ie, if we're in a CLI
  ; context, get the program to interpret the commands as OS commands.
  ; Otherwise, jump to a location where there are custom parsing/interpretion
  ; routines (for user programs).
  ; To do this, might need to use vectors/indirection so that parsing
  ; routine knows which command table to use. Or is this all getting a bit
  ; difficult?
  LED_ON LED_BUSY
  LED_OFF LED_ERR
  LED_OFF LED_OK
  LED_OFF LED_DEBUG
  lda STDIN_STATUS_REG                   ; Get our info register
  eor #STDIN_NUL_RCVD_FLG                ; Zero the received flag
  sta STDIN_STATUS_REG                   ; and re-save the register
  jsr parse_input                       ; Puts command token in FUNC_RESULT
  lda FUNC_RESULT                       ; Get the result
  cmp #CMD_TKN_NUL
  beq process_input_nul
  cmp #CMD_TKN_FAIL                     ; This means a syntax error
  beq process_input_fail
  cmp #PARSE_ERR_CODE                   ; This means a syntax error
  beq process_input_fail
  sta BARLED_CMD                        ; Display on barled
  \\ anything other than CMD_TKN_NUL and CMD_TKN_FAIL should be a valid token
  sec
  sbc #$80                        ; This turns the token into an offset for our
  asl A                           ; cmdprcptrs table, once it's multiplied by 2
  tay                             ; Transfer to Y to use as an offset
  lda cmdprcptrs,Y                ; Load LSB of pointer
  sta TBL_VEC_L                   ; and store in our table vector
  lda cmdprcptrs+1,Y              ; Load MSB of pointer
  sta TBL_VEC_H                   ; and also store in table vector
  jmp (TBL_VEC_L)                 ; Now jump to location indicated by pointer
.process_input_fail
  lda #PARSE_ERR_CODE
  sta FUNC_ERR
  jsr os_print_error
.process_input_nul
  jsr acia_prtprompt
  jmp process_input_done

;.main_service_SC28L92
;  lda STDIN_STATUS_REG             ; Clear the NUL_RECVD and BUF_FULL flags
;  and #DUART_RxA_CLR_FLAGS
;  sta STDIN_STATUS_REG
  
  jmp mainloop

\ ******************************************************************************
\ ***   COMMAND PROCESS FUNCTIONS                                            ***
\ ******************************************************************************

\-------------------------------------------------------------------------------
\ --- CMD: *                                                                 ---
\-------------------------------------------------------------------------------
.cmdprcSTAR
  jmp cmdprc_end
INCLUDE "include/cmds_B.asm"
INCLUDE "include/cmds_H.asm"
INCLUDE "include/cmds_J.asm"
INCLUDE "include/cmds_L.asm"
INCLUDE "include/cmds_P.asm"
INCLUDE "include/cmds_R.asm"
INCLUDE "include/cmds_S.asm"
INCLUDE "include/cmds_V.asm"
.cmdprc_fail
  jsr os_print_error
.cmdprc_end
  jsr acia_prtprompt
.process_input_done
  stz STDIN_IDX                 ; reset RX buffer index
  LED_OFF LED_BUSY
  jmp mainloop                  ; go around again

INCLUDE "include/funcs_VIAA.asm"
INCLUDE "include/funcs_uart_6551_acia.asm"
;INCLUDE "include/funcs_uart_SC28L92.asm"
INCLUDE "include/funcs_VIAB_ZolaDOS.asm"
;INCLUDE "include/funcs_VIAC_barled.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
;INCLUDE "include/funcs_math.asm"
INCLUDE "include/funcs_VIAA_2x16_lcd.asm"
=======

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

  cmp #PARSE_ERR_CODE         ; this means a syntax error
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
  lda #PARSE_ERR_CODE
  sta FUNC_ERR
  jsr print_error

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
  ; X currently contains the buffer index for the rest of the text in the RX 
  ; buffer (after the command), although the first char is likely to be a space.
  stz FUNC_ERR
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
  lda UART_RX_BUF,X         ; should be null. Anything else is a mistake
  cmp #0
  bne cmdprcLM_chk_fail
  jsr display_memory
  jmp cmdprc_end

;-------------------------------------------------------------------------------
; --- CMD: LP  : list memory page                                            ---
;-------------------------------------------------------------------------------
.cmdprcLP
  jsr read_hex_byte         ; read 2 hex chars from input: result in FUNC_RESULT
  lda #0                    ; check for error
  cmp FUNC_ERR
  bne cmdprcLP_fail
.cmdprcLP_chk_nul           ; check there's nothing left in the RX buffer
  lda UART_RX_BUF,X         ; should be null. Anything else is a mistake
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
  jsr print_error
.cmdprc_end
  jsr serial_send_prompt

.process_rx_done
;  jsr serial_send_prompt
  stz UART_RX_IDX               ; reset RX buffer index
  cli
  jmp mainloop                  ; go around again

;INCLUDE "include/cmd_proc.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
INCLUDE "include/funcs_math.asm"
INCLUDE "include/funcs_serial.asm"
INCLUDE "include/funcs_via_2x16_lcd.asm"
>>>>>>> e853aa37500bdedde611b732996f55e234f8d23a
INCLUDE "include/data_tables.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

.version_str
<<<<<<< HEAD
  equs "ZolOS v.21", 0

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Call Jump Table                                      
\ Jump table for OS calls. Requires corresponding entries in:
\    - cfg_page_2.asm - OS Indirection Table
\    - cfg_main.asm   - OS Function Address Table
\    - this file      - OS default config routine & this OS Call Jump Table
\ These entries must be in the same order as those in the OS Function Address 
\ Table in cfg_main.asm.
\-------------------------------------------------------------------------------
ORG $FF00
.os_calls
  jmp (OSRDHBYTE_VEC)
  jmp (OSRDHADDR_VEC)
  jmp (OSRDCH_VEC)
  jmp (OSRDFNAME_VEC)

  jmp (OSWRBUF_VEC)
  jmp (OSWRCH_VEC) 
  jmp (OSWRERR_VEC)
  jmp (OSWRMSG_VEC)
  jmp (OSWRSBUF_VEC)

  jmp (OSB2HEX_VEC)
  jmp (OSHEX2B_VEC)

  jmp (OSLCDCH_VEC)
  jmp (OSLCDCLS_VEC)
  jmp (OSLCDERR_VEC)
  jmp (OSLCDMSG_VEC)
  jmp (OSLCDPRB_VEC)
  jmp (OSLCDSC_VEC)
  
  jmp (OSUSRINT_VEC)

ORG $FFF4
.reset
  jmp soft_reset
  jmp main
.boot
  equw NMI_handler                          ; Vector for NMI
  equw startcode                            ; Reset vector to start of ROM code
  equw IRQ_handler                          ; Vector for ISR

.endrom

SAVE "bin/z64-ROM-21.bin", startrom, endrom
=======
  equs "ZolOS v.11", 0

ORG $fffa
  equw NMI_handler  ; vector for NMI
  equw startcode    ; reset vector to start of ROM code
  equw ISR_handler  ; vector for ISR

.endrom

SAVE "bin/z64-ROM-11.bin", startrom, endrom
>>>>>>> e853aa37500bdedde611b732996f55e234f8d23a
