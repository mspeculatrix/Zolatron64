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
; INCLUDE "../../LIB/cfg_dev.asm"
; INCLUDE "../../LIB/cfg_parallel.asm"
; INCLUDE "../../LIB/cfg_prt.asm"
; INCLUDE "../../LIB/cfg_spi_rtc_ds3234.asm"
; INCLUDE "../../LIB/cfg_spi_sd.asm"
; INCLUDE "../../LIB/cfg_spi65.asm"
; INCLUDE "../../LIB/cfg_uart_SC28L92.asm"
; INCLUDE "../../LIB/cfg_user_port.asm"
INCLUDE "../../LIB/cfg_ZolaDOS.asm"

DATA_START   = $7000
DATA_END     = $700C

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
  equs "DATA",0         ; @ $080D Short name, max 15 chars - null terminated
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

\ SET UP DATA SECTION
  lda #$FF                    ; Header
  sta DATA_START              ;   "
  lda #<DATA_START            ; Load address
  sta DATA_START + 1          ;   "
  lda #>DATA_START            ;   "
  sta DATA_START + 2          ;   "
  lda #'D'                    ; File type indicator
  sta DATA_START + 3
  ldx #3
  ldy #0
.setdata
  inx
  lda savedata,Y
  beq setdata_end
  sta DATA_START,X
  iny
  jmp setdata
.setdata_end
  lda #0
  sta DATA_START,X

\ *** SAVE TO FILE
  stz FUNC_ERR
  lda #<DATA_START                    ; Set start location of data
  sta TMP_ADDR_A
  lda #>DATA_START
  sta TMP_ADDR_A + 1
  lda #<DATA_END                      ; Set end location of data
  sta TMP_ADDR_B
  lda #>DATA_END
  sta TMP_ADDR_B + 1
  jsr set_datafile                    ; Set data filename
  lda #ZD_OPCODE_SAVE_DAT0            ; Set opcode for saving data
  jsr OSZDSAVE                        ; Save data
  lda FUNC_ERR
  beq write_success
  LOAD_MSG writedata_failed_msg
  jmp write_data_end
.write_success
  LOAD_MSG writedata_success_msg
.write_data_end
  jsr OSWRMSG

.prog_end
  jmp OSSFTRST

\ ------------------------------------------------------------------------------
\ ---  FUNCTIONS
\ ------------------------------------------------------------------------------
.set_datafile
  ldx #0                              ; Set filename
.set_datafile_loop
  lda filename,X
  sta STR_BUF,X
  inx
  cmp #0
  bne set_datafile_loop
  rts

\ ------------------------------------------------------------------------------
\ ---  DATA
\ ------------------------------------------------------------------------------

.filename
  equs "DATATEST.DAT"

.savedata
  equs "savedata",0

.writedata_success_msg
  equs "File write succeeded.",10,0

.writedata_failed_msg
  equs "File write FAILED!",10,0

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY FUNCTION FILES
\ ------------------------------------------------------------------------------
; INCLUDE "../../LIB/funcs_addr.asm"
; INCLUDE "../../LIB/funcs_chk_char.asm"
; INCLUDE "../../LIB/funcs_keyb.asm"
; INCLUDE "../../LIB/funcs_prng.asm"
; INCLUDE "../../LIB/funcs_spi_rtc_alarm.asm"
; INCLUDE "../../LIB/funcs_spi_rtc_common.asm"
; INCLUDE "../../LIB/funcs_spi_rtc_date.asm"
; INCLUDE "../../LIB/funcs_spi_rtc_sram.asm"
; INCLUDE "../../LIB/funcs_spi_rtc_time.asm"
; INCLUDE "../../LIB/funcs_spi_sd-dev.asm"
; INCLUDE "../../LIB/funcs_spi_sd.asm"
; INCLUDE "../../LIB/funcs_spi_sram.asm"
; INCLUDE "../../LIB/funcs_spi_dev.asm"
; INCLUDE "../../LIB/math_uint8_div.asm"
; INCLUDE "../../LIB/math_uint8_mult.asm"
; INCLUDE "../../LIB/math_uint16_add.asm"
; INCLUDE "../../LIB/math_uint16_div_uint8.asm"
; INCLUDE "../../LIB/math_uint16_div.asm"
; INCLUDE "../../LIB/math_uint16_sub.asm"
; INCLUDE "../../LIB/math_uint16_times10.asm"
; INCLUDE "../../LIB/math_uint32_add.asm"
; INCLUDE "../../LIB/math_uint32_div8.asm"
; INCLUDE "../../LIB/math_uint32_div16.asm"
; INCLUDE "../../LIB/math_uint32_mult8.asm"
; INCLUDE "../../LIB/math_uint32_mult32.asm"
; INCLUDE "../../LIB/math_uint32_add.asm"

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/DATA.EXE", header, endcode
