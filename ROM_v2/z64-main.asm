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
INCLUDE "../LIB/cfg_uart_SC28L92.asm"
; INCLUDE "../LIB/cfg_flash-io-snd.asm"
INCLUDE "../LIB/cfg_2x16_lcd.asm"
INCLUDE "../LIB/cfg_ZolaDOS.asm"
INCLUDE "../LIB/cfg_user_port.asm"
INCLUDE "../LIB/cfg_parallel.asm"
INCLUDE "../LIB/cfg_prt.asm"

\ ----- INITIALISATION ---------------------------------------------------------
ORG $8000             ; Using only the top 16KB of a 32KB EEPROM.
.startrom             ; This is where the ROM bytes start for the file, but...
ORG ROMSTART          ; This is where the actual code starts.
  jmp startcode
.version_str
  equs "ZolOS v2.1", 0
.startcode
  sei                 ; Don't interrupt me yet
  cld                 ; We don' need no steenkin' BCD
  ldx #$ff            ; Set stack pointer to $01FF - only need to set
  txs                 ; the LSB, as MSB is assumed to be $01

; Initialise registers etc
  stz TIMER_STATUS_REG
  stz FLASH_BANK
  stz FUNC_ERR
  stz FUNC_RESULT
  stz STDIN_BUF
  stz STDIN_IDX
  stz STDIN_STATUS_REG

  lda #<USR_PAGE      ; Initialise LOMEM to start of user RAM
  sta LOMEM
  lda #>USR_PAGE
  sta LOMEM + 1

\ ----- SETUP OS CALL VECTORS --------------------------------------------------
  lda #<read_hex_byte       ; OSRDHBYTE
  sta OSRDHBYTE_VEC
  lda #>read_hex_byte
  sta OSRDHBYTE_VEC + 1
  lda #<read_hex_addr       ; OSRDHADDR
  sta OSRDHADDR_VEC
  lda #>read_hex_addr
  sta OSRDHADDR_VEC + 1
  lda #<read_char           ; OSRDCH
  sta OSRDCH_VEC
  lda #>read_char
  sta OSRDCH_VEC + 1
  lda #<read_int16          ; OSRDINT16
  sta OSRDINT16_VEC
  lda #>read_int16
  sta OSRDINT16_VEC + 1
  lda #<read_filename       ; OSRDFNAME
  sta OSRDFNAME_VEC
  lda #>read_filename
  sta OSRDFNAME_VEC + 1

  lda #<duart_sendbuf        ; OSWRBUF
  sta OSWRBUF_VEC
  lda #>duart_sendbuf
  sta OSWRBUF_VEC + 1
  lda #<duart_sendchar      ; OSWRCH
  sta OSWRCH_VEC
  lda #>duart_sendchar
  sta OSWRCH_VEC + 1
  lda #<os_print_error      ; OSWRERR
  sta OSWRERR_VEC
  lda #>os_print_error
  sta OSWRERR_VEC + 1
  lda #<duart_println        ; OSWRMSG
  sta OSWRMSG_VEC
  lda #>duart_println
  sta OSWRMSG_VEC + 1
  lda #<duart_snd_strbuf     ; OSWRSBUF
  sta OSWRSBUF_VEC
  lda #>duart_snd_strbuf
  sta OSWRSBUF_VEC + 1

  lda #<byte_to_hex_str     ; OSB2HEX
  sta OSB2HEX_VEC
  lda #>byte_to_hex_str
  sta OSB2HEX_VEC + 1
  lda #<byte_to_int_str     ; OSB2ISTR
  sta OSB2ISTR_VEC
  lda #>byte_to_int_str
  sta OSB2ISTR_VEC + 1
  lda #<hex_str_to_byte     ; OSHEX2B
  sta OSHEX2B_VEC
  lda #>hex_str_to_byte
  sta OSHEX2B_VEC + 1

  lda #<uint16_to_hex_str   ; OSU16HEX
  sta OSU16HEX_VEC
  lda #>uint16_to_hex_str
  sta OSU16HEX_VEC + 1
  lda #<asc_hex_to_dec     ; OSHEX2DEC
  sta OSHEX2DEC_VEC
  lda #>asc_hex_to_dec
  sta OSHEX2DEC_VEC + 1

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
  lda #<lcd_print_byte      ; OSLCDB2HEX
  sta OSLCDB2HEX
  lda #>lcd_print_byte
  sta OSLCDB2HEX + 1
  lda #<lcd_prt_sbuf        ; OSLCDSBUF
  sta OSLCDSBUF_VEC
  lda #>lcd_prt_sbuf
  sta OSLCDSBUF_VEC + 1
  lda #<lcd_set_cursor      ; OSLCDSC 
  sta OSLCDSC_VEC
  lda #>lcd_set_cursor
  sta OSLCDSC_VEC + 1

  lda #<prt_stdout_buf      ; OSPRTBUF 
  sta OSPRTBUF_VEC
  lda #>prt_stdout_buf
  sta OSPRTBUF_VEC + 1
  lda #<prt_char            ; OSPRTCH 
  sta OSPRTCH_VEC
  lda #>prt_char
  sta OSPRTCH_VEC + 1
  lda #<prt_init            ; OSPRTINIT 
  sta OSPRTINIT_VEC
  lda #>prt_init
  sta OSPRTINIT_VEC + 1
  lda #<prt_msg             ; OSPRTMSG 
  sta OSPRTMSG_VEC
  lda #>prt_msg
  sta OSPRTMSG_VEC + 1
  lda #<prt_str_buf         ; OSPRTSBUF 
  sta OSPRTSBUF_VEC
  lda #>prt_str_buf
  sta OSPRTSBUF_VEC + 1


  lda #<zd_loadfile         ; OSZDLOAD
  sta OSZDLOAD
  lda #>zd_loadfile
  sta OSZDLOAD + 1

; OSUSRINT

  lda #<delay               ; OSDELAY
  sta OSDELAY_VEC
  lda #>delay
  sta OSDELAY_VEC + 1

; Select serial as default input/output streams
;  lda #STR_SEL_SERIAL       ; not used yet
;  sta STREAM_SELECT_REG

; SETUP LCD display & LEDs
  lda #%11111111  
  sta LCDV_DDRB   ; Set all pins on port B to output - data for LCD
  sta LCDV_DDRA   ; Set all pins on port A to output - signals for LCD & LEDs
  lda #LCD_TYPE         ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #LCD_MODE         ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #LCD_CLS          ; clear display, reset display memory
  jsr lcd_cmd

; SETUP USER PORT
  lda #$FF
  sta USRP_DDRA         ; Set all lines on user ports as outputs
  sta USRP_DDRB
  stz USRP_PORTA        ; And set all lines to low
  stz USRP_PORTB

; SETUP ZolaDOS RPi INTERFACE
  jsr zd_init

; SETUP SERIAL PORTS
  jsr duart_init

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
  PRT_MSG start_msg, duart_println
  lda #CHR_LINEEND
  jsr OSWRCH
  PRT_MSG version_str, duart_println

;  jsr lcd_clear_buf                 ; Clear LCD buffer
  PRT_MSG version_str, lcd_println  ; Print initial messages on LCD
  PRT_MSG start_msg, lcd_println
  
  lda #<500                         ; interval for delay function - in ms
  sta LCDV_TIMER_INTVL
  lda #>500
  sta LCDV_TIMER_INTVL+1
  
  LED_OFF LED_ERR
  LED_OFF LED_BUSY
  LED_OFF LED_OK
  LED_OFF LED_FILE_ACT
  LED_OFF LED_DEBUG

  cli                     	        ; Enable interrupts

.soft_reset
  SERIAL_PROMPT

\ --------- MAIN LOOP ----------------------------------------------------------
.mainloop                               ; Loop forever
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  bne process_input                     ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs process_input                     ; Branch if X >= STR_BUF_LEN
;.main_chk_usrp
;  jsr usrp_chk_timer                    ; Result will be in FUNC_RESULT
;  lda FUNC_RESULT
;  cmp #LESS_THAN
;  beq mainloop
  jmp mainloop                          ; Loop
\ --------- end of main loop ---------------------------------------------------

.process_input
  \\ We're here because the null received bit is set or STDIN_BUF full
  LED_ON LED_BUSY
  LED_OFF LED_ERR
  LED_OFF LED_OK
  LED_OFF LED_DEBUG
  lda STDIN_STATUS_REG                    ; Get our info register
  and #STDIN_CLEAR_FLAGS                  ; Clear the received flags
  sta STDIN_STATUS_REG                    ; and re-save the register
  jsr parse_input                         ; Puts command token in FUNC_RESULT
  lda FUNC_RESULT                         ; Get the result
  cmp #CMD_TKN_NUL
  beq process_input_nul
  cmp #CMD_TKN_FAIL                       ; This means a syntax error
  beq process_input_fail
  cmp #PARSE_ERR_CODE                     ; This means a syntax error
  beq process_input_fail
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
  SERIAL_PROMPT
  jmp process_input_done

\ ******************************************************************************
\ ***   COMMAND PROCESS FUNCTIONS                                            ***
\ ******************************************************************************

.cmdprcSTAR
  jmp cmdprc_end
INCLUDE "include/cmds_B.asm"
;INCLUDE "include/cmds_F.asm"
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
  SERIAL_PROMPT
.process_input_done
  stz STDIN_IDX                                   ; Reset RX buffer index
  stz STDIN_BUF
  LED_OFF LED_BUSY
  jmp mainloop                                    ; Go around again

INCLUDE "include/funcs_uart_SC28L92.asm"
INCLUDE "include/funcs_ZolaDOS.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_isr.asm"
INCLUDE "../LIB/funcs_math.asm"
INCLUDE "include/funcs_2x16_lcd.asm"
INCLUDE "include/funcs_prt.asm"
INCLUDE "include/data_tables.asm"

ALIGN &100                                        ; Start on new page
.NMI_handler                                      ; For future development
.exit_nmi
  rti
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
  jmp (OSB2ISTR_VEC)
  jmp (OSHEX2B_VEC)
  jmp (OSU16HEX_VEC)
  jmp (OSHEX2DEC_VEC)

  jmp (OSLCDCH_VEC)
  jmp (OSLCDCLS_VEC)
  jmp (OSLCDERR_VEC)
  jmp (OSLCDMSG_VEC)
  jmp (OSLCDB2HEX_VEC)
  jmp (OSLCDSBUF_VEC)
  jmp (OSLCDSC_VEC)
  
  jmp (OSPRTBUF_VEC)
  jmp (OSPRTCH_VEC)
  jmp (OSPRTINIT_VEC)
  jmp (OSPRTMSG_VEC)
  jmp (OSPRTSBUF_VEC)

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

SAVE "bin/z64-ROM-2.1.bin", startrom, endrom
