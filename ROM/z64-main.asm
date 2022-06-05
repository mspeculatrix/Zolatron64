\ ROM code for Zolatron 64 6502-based microcomputer.
\
\ GitHub: https://github.com/mspeculatrix/Zolatron64/
\ Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
\
\ Written for the Beebasm assembler. Assemble with:
\     beebasm -v -i z64-main.asm
\
\ Write to EEPROM with:
\     minipro -p AT28C256 -w z64-ROM-<version>.bin

CPU 1                                             ; Use 65C02 instruction set

; Include our setup files. These contain address designations and constant
; definitions.
INCLUDE "../LIB/cfg_main.asm"
INCLUDE "../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../LIB/cfg_page_2.asm"                   ; OS Indirection Table
; PAGE 3 is used for I/O buffers, plus indexes, defined in cfg_main.asm
INCLUDE "../LIB/cfg_page_4.asm"                   ; Misc buffers etc
; PAGE 5 - Reserved for user program workspace
; PAGE 6 - ZolaDOS workspace
; PAGE 7 - Reserved for future expansion

INCLUDE "include/cfg_ROM.asm"
INCLUDE "../LIB/cfg_uart_6551_acia.asm"
;INCLUDE "../LIB/cfg_uart_SC28L92.asm"
INCLUDE "../LIB/cfg_VIAA.asm"
INCLUDE "../LIB/cfg_2x16_lcd.asm"
INCLUDE "../LIB/cfg_VIAB_ZolaDOS.asm"
INCLUDE "../LIB/cfg_VIAC.asm"
INCLUDE "../LIB/cfg_VIAD_parallel.asm"

\ ----- INITIALISATION ---------------------------------------------------------
ORG $8000             ; Using only the top 16KB of a 32KB EEPROM.
.startrom             ; This is where the ROM bytes start for the file, but...
ORG ROMSTART          ; This is where the actual code starts.
.startcode
  sei                 ; Don't interrupt me yet
  cld                 ; We don' need no steenkin' BCD
  ldx #$ff            ; Set stack pointer to $01FF - only need to set
  txs                 ; the LSB, as MSB is assumed to be $01

  stz TIMER_STATUS_REG
  stz FLASH_BANK

\ ----- SETUP OS CALL VECTORS --------------------------------------------------
  lda #<read_hex_byte       ; OSRDHBYTE
  sta OSRDHBYTE_VEC
  lda #>read_hex_byte
  sta OSRDHBYTE_VEC + 1
  lda #<read_hex_addr       ; OSRDHADDR
  sta OSRDHADDR_VEC
  lda #>read_hex_addr
  sta OSRDHADDR_VEC + 1
  ;lda #<read_char           ; OSRDCH
  ;sta OSRDCH_VEC
  ;lda #>read_char
  ;sta OSRDCH_VEC + 1
  lda #<read_int16          ; OSRDINT16
  sta OSRDINT16_VEC
  lda #>read_int16
  sta OSRDINT16_VEC + 1
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

  lda #<zd_loadfile         ; OSZDLOAD
  sta OSZDLOAD
  lda #>zd_loadfile
  sta OSZDLOAD + 1

; OSUSRINT

  lda #<delay               ; OSDELAY
  sta OSDELAY_VEC
  lda #>delay
  sta OSDELAY_VEC + 1


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

; SETUP LCD
  lda #LCD_TYPE         ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #LCD_MODE         ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #LCD_CLS          ; clear display, reset display memory
  jsr lcd_cmd

\ ------------------------------------------------------------------------------
\ ----     MAIN PROGRAM                                                     ----
\ ------------------------------------------------------------------------------
.main
  LED_ON LED_ERR
  LED_ON LED_BUSY
  LED_ON LED_OK
  LED_ON LED_FILE_ACT
  LED_ON LED_DEBUG
 
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
;  jsr delay
  LED_OFF LED_ERR
;  jsr delay
  LED_OFF LED_BUSY
;  jsr delay
  LED_OFF LED_OK
;  jsr delay
  LED_OFF LED_FILE_ACT
;  jsr delay
  LED_OFF LED_DEBUG

  cli                     	        ; Enable interrupts

.soft_reset
  jsr acia_prtprompt

\ --------- MAIN LOOP ----------------------------------------------------------
.mainloop                               ; Loop forever
.main_chk_stdin
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG               ; Is the 'null received' bit set?
  bne process_input                     ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs process_input                     ; Branch if X >= STR_BUF_LEN
;.main_chk_SC28L92
;  lda STDIN_STATUS_REG                  ; Load our serial status register
;  and #DUART_RxA_BUF_FULL_FL
;  bne main_service_SC28L92
;  and DUART_RxA_NUL_RCVD_FL
;  bne main_service_SC28L92
;  jmp main_chk_viac                     ; If 0, on to next check
;.main_chk_viac
;  jsr viac_chk_timer                    ; Result will be in FUNC_RESULT
;  lda FUNC_RESULT
;  cmp #LESS_THAN
;  beq mainloop
;  jsr barled_count
  jmp mainloop                          ; Loop
\ --------- end of main loop ---------------------------------------------------

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
  lda STDIN_STATUS_REG                    ; Get our info register
  eor #STDIN_NUL_RCVD_FLG                 ; Zero the received flag
  sta STDIN_STATUS_REG                    ; and re-save the register
  jsr parse_input                         ; Puts command token in FUNC_RESULT
  lda FUNC_RESULT                         ; Get the result
  cmp #CMD_TKN_NUL
  beq process_input_nul
  cmp #CMD_TKN_FAIL                       ; This means a syntax error
  beq process_input_fail
  cmp #PARSE_ERR_CODE                     ; This means a syntax error
  beq process_input_fail
  sta BARLED_CMD                          ; Display on barled
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
;  lda STDIN_STATUS_REG           ; Clear the NUL_RECVD and BUF_FULL flags
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
INCLUDE "include/cmds_F.asm"
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
  ldx #0
  stx STDIN_IDX
  jsr acia_prtprompt
.process_input_done
  stz STDIN_IDX                                   ; Reset RX buffer index
  LED_OFF LED_BUSY
  jmp mainloop                                    ; Go around again

INCLUDE "include/funcs_VIAA.asm"
INCLUDE "include/funcs_uart_6551_acia.asm"
;INCLUDE "include/funcs_uart_SC28L92.asm"
INCLUDE "include/funcs_VIAB_ZolaDOS.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
INCLUDE "../LIB/funcs_math.asm"
INCLUDE "include/funcs_VIAA_2x16_lcd.asm"
INCLUDE "include/funcs_VIAD_parallel.asm"
INCLUDE "include/data_tables.asm"

ALIGN &100        ; start on new page
.NMI_handler      ; for future development
.exit_nmi
  rti

.version_str
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
  jmp (OSRDINT16_VEC)
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
  
  jmp (OSZDLOAD_VEC)

;  jmp (OSFLOAD_VEC)

  jmp (OSUSRINT_VEC)
  jmp (OSDELAY_VEC)

ORG $FFF4
.reset
  jmp soft_reset                      ; Print prompt and go to start of mainloop
  jmp main                            ; Harder reset - go to start of ROM code
.boot
  equw NMI_handler                          ; Vector for NMI
  equw startcode                            ; Reset vector to start of ROM code
  equw IRQ_handler                          ; Vector for ISR

.endrom

SAVE "bin/z64-ROM-22.bin", startrom, endrom
