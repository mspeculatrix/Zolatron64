; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i <filename>.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"    ; System ero page addresses
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"    ; OS Indirection Table
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"    ; Misc buffers etc
; PAGE 5 is available for user code workspace
; PAGE 6 - ZolaDOS workspace
INCLUDE "../../LIB/cfg_page_7.asm"    ; SPI, RTC, SD addresses etc

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY CONFIG FILES
\ ------------------------------------------------------------------------------
; INCLUDE "../../LIB/cfg_parallel.asm"
; INCLUDE "../../LIB/cfg_prt.asm"
; INCLUDE "../../LIB/cfg_user_port.asm"
; INCLUDE "../../LIB/cfg_ZolaDOS.asm"
; INCLUDE "../../LIB/cfg_chk_char.asm"
INCLUDE "../../LIB/cfg_spi65.asm"
INCLUDE "../../LIB/cfg_spi_rtc_ds3234.asm"


ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ; $4C followed by 2-byte address
  equb "E"                  ; @ $0803 E=executable, D=data, O=overlay, X=OS ext
  equb <header              ; @ $0804 Entry address
  equb >header
  equb <reset               ; @ $0806 Reset address
  equb >reset
  equb <endcode             ; @ $0808 Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "SETDATE",0          ; @ $080D Short name, max 15 chars - null terminated
.version_string
  equs "1.0",0              ; Version string - null terminated

.startprog                  ; Start of main program code
.reset                      ; May sometimes be different from startprog
  sei                       ; Turn off interrupts
  cld                       ; Turn off BCD
  ldx #$ff                  ; Set stack pointer to $01FF - only need to set the
  txs                       ; LSB, as MSB is assumed to be $01

  stz PRG_EXIT_CODE         ; Should have an OS routine for initialising progs?
  stz FUNC_ERR
  stz FUNC_RESULT
  cli

\ ------------------------------------------------------------------------------
\ ---  MAIN PROGRAM
\ ------------------------------------------------------------------------------
.main
  jsr rtc_select

  LOAD_MSG start_msg
  jsr OSWRMSG
  jsr rtc_init

.get_day
  LOAD_MSG get_day_msg
  jsr OSWRMSG
  jsr get_number
  lda FUNC_ERR
  beq get_day_chk
  jmp input_error
.get_day_chk
  lda FUNC_RES_L
  beq error_invalid_entry   ; 0 is not valid
  cmp #32
  bcs error_invalid_entry
  sta RTC_DAT_BUF

.get_month
  LOAD_MSG get_month_msg
  jsr OSWRMSG
  jsr get_number
  lda FUNC_ERR
  beq get_month_chk
  jmp input_error
.get_month_chk
  lda FUNC_RES_L
  beq error_invalid_entry   ; 0 is not valid
  cmp #13
  bcs error_invalid_entry
  sta RTC_DAT_BUF + 1

.get_year
  LOAD_MSG get_year_msg
  jsr OSWRMSG
  jsr get_number
  lda FUNC_ERR
  beq get_year_chk
  jmp input_error
.get_year_chk
  lda FUNC_RES_L
  beq error_invalid_entry   ; 0 is not valid
  cmp #100
  bcs error_invalid_entry
  sta RTC_DAT_BUF + 2

.get_dow
  LOAD_MSG get_dow_msg
  jsr OSWRMSG
  jsr get_number
  lda FUNC_ERR
  beq get_dow_chk
  jmp input_error
.get_dow_chk
  lda FUNC_RES_L
  cmp #7
  bcs error_invalid_entry
  sta RTC_DAT_BUF + 3

  jsr rtc_set_date

  jsr OSRDDATE
  jsr rtc_display_date
  NEWLINE

  jmp prog_end

.error_invalid_entry
  LOAD_MSG err_inv_entry
  jsr OSWRMSG
  jmp prog_end

.input_error
  LOAD_MSG err_input
  jsr OSWRMSG

.prog_end
  jmp OSSFTRST

\ ------------------------------------------------------------------------------
\ ---  FUNCTIONS
\ ------------------------------------------------------------------------------

.get_number
  stz STDIN_IDX
  stx STDIN_BUF
  stz FUNC_ERR
.get_number_loop
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FL                ; Is the 'null received' bit set?
  bne get_number_process                ; If yes, process the buffer
  ldx STDIN_IDX                         ; Load the value of the RX buffer index
  cpx #STR_BUF_LEN                      ; Are we at the limit?
  bcs get_number_process                ; Branch if X >= STR_BUF_LEN
  jmp get_number_loop
.get_number_process
  lda STDIN_STATUS_REG                  ; Get our info register
  eor #STDIN_NUL_RCVD_FL                ; Zero the received flag
  sta STDIN_STATUS_REG                  ; and re-save the register
  stz STDIN_IDX                         ; Want to read from first char in buf
  jsr OSRDINT16                         ; Going to use only lower byte value
  rts


\ ------------------------------------------------------------------------------
\ ---  DATA
\ ------------------------------------------------------------------------------

.start_msg
  equs "Setting RTC date",10,0
.get_day_msg
  equs "Enter day (1-31)  : ",0
.get_month_msg
  equs "Enter month (1-12): ",0
.get_year_msg
  equs "Enter year (00-99): 20",0
.get_dow_msg
  equs "Enter day",10
  equs "(0=Mon, 6=Sun)    : ",0
.err_inv_entry
  equs "Invalid entry",10,0
.err_input
  equs "Input error",10,0

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY FUNCTION FILES
\ ------------------------------------------------------------------------------
INCLUDE "../../LIB/math_uint8_mult.asm"
INCLUDE "../../LIB/math_uint8_div.asm"
INCLUDE "../../LIB/funcs_spi_rtc_common.asm"
INCLUDE "../../LIB/funcs_spi_rtc_date.asm"
;INCLUDE "../../LIB/funcs_spi_rtc_time.asm"

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/SETDATE.EXE", header, endcode
