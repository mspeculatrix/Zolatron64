\ ROM code for Zolatron 64 6502-based microcomputer.
\
\ GitHub: https://github.com/mspeculatrix/Zolatron64/
\ Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
\
\ Written for the Beebasm assembler. Assemble with:
\     beebasm -v -i z64-main.asm -o z64-ROM.bin -S -VSTR="<version>"
\
\ Write to EEPROM with:
\     minipro -p AT28C256 -w z64-ROM-<version>.bin

CPU 1                   ; Use 65C02 instruction set
VSTR =? "0.0.0"         ; Version string. Will be overwritten with the -S option

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
INCLUDE "../LIB/cfg_page_7.asm"                   ; SPI

INCLUDE "include/cfg_ROM.asm"
INCLUDE "../LIB/cfg_uart_SC28L92.asm"
; INCLUDE "../LIB/cfg_flash-io-snd.asm"
INCLUDE "../LIB/cfg_4x20_lcd.asm"
INCLUDE "../LIB/cfg_ZolaDOS.asm"
INCLUDE "../LIB/cfg_user_port.asm"
INCLUDE "../LIB/cfg_parallel.asm"
INCLUDE "../LIB/cfg_prt.asm"
INCLUDE "../LIB/cfg_spi65.asm"
INCLUDE "../LIB/cfg_spi_rtc_ds3234.asm"

\ ------------------------------------------------------------------------------
\ ----    INITIALISATION                                                    ----
\ ------------------------------------------------------------------------------
ORG $8000              ; Using only the top 16KB of a 32KB EEPROM. This is
                       ; where the bytes start for the ROM file, but...
.startrom
ORG ROM_START          ; This is where the actual code starts.
  jmp startcode
.version_str
  equs VSTR, 0
.startcode
  sei                       ; Don't interrupt me yet
  cld                       ; We don' need no steenkin' BCD
  ldx #$ff                  ; Set stack pointer to $01FF - only need to set
  txs                       ; the LSB, as MSB is assumed to be $01

; Initialise registers etc
  stz SYS_REG
  stz IRQ_REG
  stz EXTMEM_BANK           ; Default to extended memory bank 0
  stz EXTMEM_SELECT         ;    "     "    "       "     "   "
  stz FUNC_ERR              ; Zero out function return values
  stz FUNC_RESULT
  ; Now doing the following at the soft reset stage
;  stz STDIN_BUF             ; Set first byte of STDIN buffer to a nul (0)
;  stz STDIN_IDX             ; and set the corresponding index
;  stz STDOUT_BUF            ; Do the same for the STDOUT buffer
;  stz STDOUT_IDX
;  stz STDIN_STATUS_REG      ; Zero out the STDIN register

  stz ZD_CTRL_REG

  lda #<USR_START           ; Initialise LOMEM to start of user RAM
  sta LOMEM
  sta PROG_END
  lda #>USR_START
  sta LOMEM + 1
  sta PROG_END + 1

INCLUDE "include/os_call_vectors.asm"

; Select serial as default input/output streams
;  lda #STR_SEL_SERIAL       ; not used yet
;  sta STREAM_SELECT_REG

\ ----  SETUP LCD display & LEDs   ---------------------------------------------
  lda SYS_REG
  ora #%00100000     ; Sets bit 5 showing we're using 20x4 display
  sta SYS_REG
  lda #%11111111
  sta LCDV_DDRB      ; Set all pins on port B to output - data for LCD
  sta LCDV_DDRA      ; Set all pins on port A to output - signals for LCD & LEDs
  lda #LCD_TYPE      ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_cmd
  lda #LCD_MODE                         ; Display on; cursor off; blink off
  jsr lcd_cmd
  lda #LCD_CLS                          ; Clear display, reset display memory
  jsr lcd_cmd

\ ----  SETUP USER PORT  -------------------------------------------------------
  lda #$FF
  sta USRP_DDRA                         ; Set all lines on user ports as outputs
  sta USRP_DDRB
  stz USRP_PORTA                        ; And set all lines to low
  stz USRP_PORTB

\ ----  SETUP ZolaDOS RPi INTERFACE  -------------------------------------------
  jsr zd_init

\ ----  SETUP SERIAL PORTS  ----------------------------------------------------
  jsr duart_init

\ ------------------------------------------------------------------------------
\ ----     MAIN PROGRAM                                                     ----
\ ------------------------------------------------------------------------------
.main
  LED_ON LED_ERR                        ; Turn on all the LEDs for a light show
  LED_ON LED_BUSY
  LED_ON LED_OK
  LED_ON LED_FILE_ACT
  LED_ON LED_DEBUG

  stz PRG_EXIT_CODE

; Print initial message & prompt via serial
  lda #CHR_LINEEND                          ; Start with a couple of line feeds
  jsr OSWRCH
  jsr OSWRCH
  PRT_MSG start_msg, duart_println          ; And now the start-up message
  lda #CHR_LINEEND
  jsr OSWRCH
  PRT_MSG version_str, duart_println
  lda #CHR_LINEEND
  jsr OSWRCH

  jsr OSLCDCLS                              ; Start-up messages on LCD
  PRT_MSG start_msg, lcd_println
  PRT_MSG version_str, lcd_println

\ -----  CHECK FOR PARALLEL PORT  ----------------------------------------------
  jsr prt_check_present                     ; Sets SYS_PARALLEL bit in SYS_REG

\ -----  CHECK FOR SPI INTERFACE BOARD  ----------------------------------------
\ Sets the SYS_SPI bit in SYS_REG
\ SPI65 device register is at $BF02
  lda #0
  sta $BF02
  lda $BF02
  bne spi_chk_not_present
  lda #3
  sta $BF02
  lda $BF02
  cmp #3
  beq spi_chk_present
.spi_chk_not_present
  lda SYS_REG
  and #SYS_SPI_NO
  sta SYS_REG
  LOAD_MSG spi_if_not_present_msg
  jmp spi_chk_done
.spi_chk_present
  lda SYS_REG
  ora #SYS_SPI
  sta SYS_REG
  LOAD_MSG spi_if_present_msg
.spi_chk_done
  jsr OSWRMSG
  jsr OSLCDMSG

\ -----  CHECK FOR EXTENDED ROM/RAM BOARD  -------------------------------------
\ Sets the SYS_EXMEM bit in SYS_REG
  lda #4                                ; Use bank 4. This is never a ROM
  sta EXTMEM_SELECT                     ; Select it
  jsr extmem_ram_chk                    ; Run a check. Sets the bit in SYS_REG
  lda FUNC_ERR
  bne boot_exmem_err                    ; If error 0, no problem
  LOAD_MSG exmem_fitted_msg
  jmp boot_exmem_def
.boot_exmem_err
  LOAD_MSG exmem_absent_msg
.boot_exmem_def
  lda #CHR_LINEEND
  jsr OSWRCH
  jsr OSWRMSG
  jsr OSLCDMSG
  stz EXTMEM_SELECT                     ; Now revert to 0 as default & select it
  stz EXTMEM_BANK                       ; Store it for some reason
  NEWLINE

; SET UP DELAY TIMER
  lda #<500                             ; Interval for delay function - in ms
  sta LCDV_TIMER_INTVL
  lda #>500
  sta LCDV_TIMER_INTVL+1

; PARALLEL INTERFACE MESSAGE
  lda SYS_REG
  and #SYS_PARALLEL                       ; Check if bit is set
  bne parallel_ok                         ; If result non-zero, then it is
  LOAD_MSG parallel_if_not_fitted
  jmp parallel_msg
.parallel_ok
  LOAD_MSG parallel_if_fitted
.parallel_msg
  jsr OSWRMSG
  NEWLINE
  jsr OSLCDMSG

  cli                     	              ; Enable interrupts

\ ------------------------------------------------------------------------------
\ -----  SOFT RESET
\ ------------------------------------------------------------------------------
.soft_reset
  LED_OFF LED_ERR                         ; Turn off the LEDs
  LED_OFF LED_BUSY
  LED_OFF LED_FILE_ACT
  LED_OFF LED_DEBUG
  LED_ON LED_OK

  stz STDIN_BUF             ; Set first byte of STDIN buffer to a nul (0)
  stz STDIN_IDX             ; and set the corresponding index
  stz STDOUT_BUF            ; Do the same for the STDOUT buffer
  stz STDOUT_IDX
  stz STDIN_STATUS_REG      ; Zero out the STDIN register

; BOOT ROM
; Check to see if there is boot ROM code in bank 0 of extended memory.
; If so, run it.
  CHK_EXTMEM_PRESENT
  bcc ready                             ; If not, skip to ready prompt
  lda EXTMEM_START + CODEHDR_TYPE       ; Load code type identifier
  cmp #TYPECODE_BOOT                    ; Is it a boot ROM?
  bne ready                             ; If not, skip to ready prompt
  jmp EXTMEM_START                      ; Otherwise, jump to ROM code

.ready
  LOAD_MSG ready_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  SERIAL_PROMPT

\ ------------------------------------------------------------------------------
\ ----- MAIN LOOP
\ ------------------------------------------------------------------------------
.mainloop                               ; Loop forever
  ; SHOULD CHECK IRQ_REG here
  ; lda IRQ_REG                         ; Load the IRQ register
  ; beq mainloop_chk_input              ; If zero, nothing to worry about
  ; otherwise deal with interrupts here
  ; stz IRQ_REG                         ; Reset flags
.mainloop_chk_input
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  bne process_input                     ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs process_input                     ; Branch if X >= STR_BUF_LEN
;.main_chk_usrp
;  jsr usrp_chk_timer                   ; Result will be in FUNC_RESULT
;  lda FUNC_RESULT
;  cmp #LESS_THAN
;  beq mainloop
  jmp mainloop                          ; Loop
\ --------- end of main loop ---------------------------------------------------

.process_input
  \ We're here because the null received bit is set or STDIN_BUF full
  LED_ON LED_BUSY
  LED_OFF LED_ERR
  LED_OFF LED_OK
  LED_OFF LED_DEBUG
  LED_OFF LED_FILE_ACT
  lda STDIN_STATUS_REG                    ; Get our info register
  and #STDIN_CLEAR_FLAGS                  ; Clear the received flags
  sta STDIN_STATUS_REG                    ; and re-save the register
  jsr parse_input                         ; Puts command token in FUNC_RESULT
  lda FUNC_RESULT                         ; Get the result
  cmp #CMD_TKN_NUL
  beq process_input_nul
  cmp #CMD_TKN_FAIL                       ; This means a syntax error
  beq process_input_nomatch
  cmp #PARSE_ERR_CODE                     ; This means no match with cmd list
  beq process_input_nomatch
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
.process_input_nomatch
  ; See if the command matches the name of an executable file.
  LED_ON LED_FILE_ACT
  LOAD_MSG searching_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  stz STDIN_IDX                   ; Reset input buffer index to 0
  ;stz STDIN_BUF
  lda #<USR_START                 ; This is where we're going to put the code
  sta FILE_ADDR
  lda #>USR_START
  sta FILE_ADDR + 1
  jsr zd_getfile                  ; Try loading an executable
  lda FUNC_ERR
  beq process_input_run           ; If error code 0, run the code
  LED_ON LED_ERR                  ; Otherwise, this is an error
  lda #PARSE_ERR_CODE
  sta FUNC_ERR
  jsr os_print_error
.process_input_nul
  SERIAL_PROMPT
  LED_OFF LED_FILE_ACT
  jmp process_input_done
.process_input_run
  jsr zd_fileload_ok
  lda #CHR_LINEEND
  jsr OSWRCH
  LED_OFF LED_FILE_ACT
  stz STDIN_IDX                   ; Reset input buffer index to 0
  stz STDIN_BUF
  jmp USR_START


\ ******************************************************************************
\ ***   COMMAND PROCESS FUNCTIONS                                            ***
\ ******************************************************************************

.cmdprcSTAR
  jmp cmdprc_end
INCLUDE "include/cmds_punc.asm"
INCLUDE "include/cmds_B.asm"
INCLUDE "include/cmds_C.asm"
INCLUDE "include/cmds_D.asm"
INCLUDE "include/cmds_H.asm"
INCLUDE "include/cmds_J.asm"
INCLUDE "include/cmds_L.asm"
INCLUDE "include/cmds_M.asm"
INCLUDE "include/cmds_O.asm"
INCLUDE "include/cmds_P.asm"
INCLUDE "include/cmds_R.asm"
INCLUDE "include/cmds_S.asm"
INCLUDE "include/cmds_V.asm"
INCLUDE "include/cmds_X.asm"
.cmdprc_success
  LED_ON LED_OK
  jmp cmdprc_end
.cmdprc_fail
  LED_ON LED_ERR
  jsr os_print_error
.cmdprc_end
  SERIAL_PROMPT
.process_input_done
  stz STDIN_IDX                                   ; Reset RX buffer index
  stz STDIN_BUF
  LED_OFF LED_BUSY
  LED_OFF LED_FILE_ACT
  jmp mainloop                                    ; Go around again


INCLUDE "include/data_tables.asm"
INCLUDE "../LIB/funcs_addr.asm"
INCLUDE "../LIB/math_uint8_div.asm"
INCLUDE "../LIB/math_uint16_div.asm"
INCLUDE "../LIB/math_uint16_times10.asm"
INCLUDE "include/funcs_uart_SC28L92.asm"
INCLUDE "include/funcs_ZolaDOS.asm"
INCLUDE "include/funcs_conv.asm"
INCLUDE "include/funcs_io.asm"
INCLUDE "include/funcs_ext_mem.asm"
INCLUDE "include/funcs_4x20_lcd.asm"
INCLUDE "include/funcs_prt.asm"
INCLUDE "include/funcs_isr.asm"
INCLUDE "include/funcs_spi65.asm"

\-------------------------------------------------------------------------------
\ ---  NMI HANDLER
\-------------------------------------------------------------------------------
ALIGN &100                                        ; Start on new page
.NMI_handler                                      ; For future development
.exit_nmi
  rti

\-------------------------------------------------------------------------------
\ OS CALLS  - OS Call Jump Table
\ Requires corresponding entries in:
\    - cfg_page_2.asm - OS Indirection Table
\    - cfg_main.asm   - OS Function Address Table
\    - os_call_vectors.asm - map functions to vectors
\ These entries must be in the same order as those in the OS Function Address
\ Table in cfg_main.asm and the Vector Location Table in cfg_page_2.asm.
\-------------------------------------------------------------------------------
ORG $FF00                     ; Must match address at start of OS Function
.os_call_jump_table           ; Address Table in cfg_main.asm
  jmp (OSGETKEY_VEC)
  jmp (OSRDASC_VEC)
  jmp (OSRDBYTE_VEC)
  jmp (OSRDCH_VEC)
  jmp (OSRDHBYTE_VEC)
  jmp (OSRDHADDR_VEC)
  jmp (OSRDINT16_VEC)
  jmp (OSRDFNAME_VEC)
  jmp (OSRDSTR_VEC)

  jmp (OSWRBUF_VEC)
  jmp (OSWRCH_VEC)
  jmp (OSWRERR_VEC)
  jmp (OSWRMSG_VEC)
  jmp (OSWROP_VEC)
  jmp (OSWRSBUF_VEC)
  jmp (OSSOAPP_VEC)
  jmp (OSSOCH_VEC)

  jmp (OSB2BIN_VEC)
  jmp (OSB2HEX_VEC)
  jmp (OSB2ISTR_VEC)
  jmp (OSHEX2B_VEC)
  jmp (OSU16HEX_VEC)
  jmp (OSU16ISTR_VEC)
  jmp (OSHEX2DEC_VEC)

  jmp (OSLCDCH_VEC)
  jmp (OSLCDCLS_VEC)
  jmp (OSLCDERR_VEC)
  jmp (OSLCDMSG_VEC)
  jmp (OSLCDB2HEX_VEC)
  jmp (OSLCDSBUF_VEC)
  jmp (OSLCDSC_VEC)
  jmp (OSLCDWRBUF_VEC)

  jmp (OSPRTBUF_VEC)
  jmp (OSPRTCH_VEC)
  jmp (OSPRTCHK_VEC)
  jmp (OSPRTINIT_VEC)
  jmp (OSPRTMSG_VEC)
  jmp (OSPRTSBUF_VEC)

  jmp (OSZDDEL_VEC)
  jmp (OSZDLOAD_VEC)
\  jmp (OSZDRBLK_VEC)                 ; Read block
\  jmp (OSZDWBLK_VEC)                 ; Write block
\  jmp (OSZDRBYTE_VEC)                ; Read byte
\  jmp (OSZDWBYTE_VEC)                ; Write byte
\  jmp (OSZDRSTR_VEC)                 ; Read string
\  jmp (OSZDWSTR_VEC)                 ; Write string
  jmp (OSZDSAVE_VEC)

  jmp (OSDELAY_VEC)
  jmp (OSUSRINT_VEC)

  jmp (OSSPIEXCH_VEC)

ORG $FFF4
.reset
  jmp soft_reset                      ; Print prompt and go to start of mainloop
  jmp main                            ; Harder reset - go to start of ROM code
.boot
  equw NMI_handler                          ; Vector for NMI
  equw startcode                            ; Reset vector to start of ROM code
  equw IRQ_handler                          ; Vector for ISR

.endrom

SAVE startrom, endrom
