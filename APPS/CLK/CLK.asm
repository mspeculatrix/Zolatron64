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
INCLUDE "../../LIB/cfg_rtc_ds3234.asm"
INCLUDE "../../LIB/cfg_spi65.asm"

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
  equs "CLK",0         ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

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

  jsr display_clock_buf

  ; Load the time "09:33:15"
  LOAD_MSG setting_buf_msg
  jsr OSWRMSG
  lda #15
  sta RTC_CLK_BUF
  lda #33
  sta RTC_CLK_BUF + 1
  lda #9
  sta RTC_CLK_BUF + 2
  jsr display_clock_buf

  LOAD_MSG writing_clk_msg
  jsr OSWRMSG
  jsr rtc_set_time

  LOAD_MSG clearing_buf_msg
  jsr OSWRMSG
  lda #0
  sta RTC_CLK_BUF
  lda #0
  sta RTC_CLK_BUF + 1
  lda #0
  sta RTC_CLK_BUF + 2
  jsr display_clock_buf

  LOAD_MSG reading_clk_msg
  jsr OSWRMSG
  jsr rtc_read_time
  jsr rtc_display_time
  NEWLINE


.prog_end
  jmp OSSFTRST

.clearing_buf_msg
  equs "Clearing buffer",10,0
.reading_clk_msg
  equs "Reading clock",10,0
.writing_clk_msg
  equs "Writing time to RTC",10,0
.setting_buf_msg
	equs "Setting buffer",10,0

.display_clock_buf
  ldx #2
.display_clock_buf_loop
  lda RTC_CLK_BUF,X
  jsr OSB2ISTR
  dec FUNC_RESULT ; Will start as 1 if result is single digit
  bne display_clock_buf_prt ; 0 if single digit
  lda #'0'
  jsr OSWRCH
.display_clock_buf_prt
  jsr OSWRSBUF
  cpx #0
  beq display_clock_buf_done
  lda #':'
  jsr OSWRCH
  dex
  jmp display_clock_buf_loop
.display_clock_buf_done
  lda #10
  jsr OSWRCH
  rts

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY FUNCTION FILES
\ ------------------------------------------------------------------------------
; INCLUDE "../../LIB/math_uint8_mult.asm"
INCLUDE "../../LIB/funcs_spi65.asm"
INCLUDE "../../LIB/funcs_spi_rtc_ds3234.asm"
INCLUDE "../../LIB/math_uint8_mult.asm"
INCLUDE "../../LIB/math_uint8_div.asm"



.endtag
  equs "EOF",0
.endcode

SAVE "../bin/CLK.EXE", header, endcode
