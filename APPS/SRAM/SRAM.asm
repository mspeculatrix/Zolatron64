; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i SRAM.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"    ; System zero page addresses
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
; INCLUDE "../../LIB/cfg_spi_rtc_ds3234.asm"

MEM_ADDR = $2000

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
  equs "SRAM",0             ; @ $080D Short name, max 15 chars - null terminated
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

  lda #$80
  sta SPI_CTRL_REG

  lda #SPI_DEV_SRAM                 ; Select the SRAM
  sta SPI_CURR_DEV

  ; -----  SETTING PAGE MODE  --------------------------------------------------
  LOAD_MSG page_mode_msg
  jsr OSWRMSG

  lda SPI_CURR_DEV
  sta SPI_DEV_SEL

  LOAD_MSG device_selected_msg
  jsr OSWRMSG
  lda SPI_DEV_SEL
  jsr OSB2HEX
  jsr OSWRSBUF
  NEWLINE

  lda SPI_DATA_REG                  ; To clear TC flag, if set
  lda #SRAM_CMD_WRMR                ; $01 Write to mode register
  jsr OSSPIEXCH
  lda #SRAM_PAGE_MODE               ; $80 Page mode
  jsr OSSPIEXCH
  stz SPI_DEV_SEL                   ; End comms

  jsr print_mem_buf

  ; -----  LOADING BUFFER  -----------------------------------------------------
  LOAD_MSG set_buf_msg
  jsr OSWRMSG
  ldx #0
  lda #$10
.load_buf_loop
  sta SPI_BUF_32,X
  inc A
  inx
  cpx #32
  bne load_buf_loop
  jsr print_mem_buf

  ; -----  WRITING TO MEMORY  --------------------------------------------------
  LOAD_MSG write_mem_msg
  jsr OSWRMSG
  lda #<MEM_ADDR
  sta TMP_ADDR_A_L
  lda #>MEM_ADDR
  sta TMP_ADDR_A_H
  jsr sram_write_page
  NEWLINE

  ; -----  CLEARING THE BUFFER  ------------------------------------------------
  LOAD_MSG clear_buf_msg
  jsr OSWRMSG
  jsr clear_buf
  jsr print_mem_buf

  ; -----  READING FROM MEMORY  ------------------------------------------------
  LOAD_MSG read_mem_msg
  jsr OSWRMSG
  lda #<MEM_ADDR
  sta TMP_ADDR_A_L
  lda #>MEM_ADDR
  sta TMP_ADDR_A_H
  jsr sram_read_page
  jsr print_mem_buf

.prog_end
  jmp OSSFTRST

\ ***** FUNCTIONS *****

.clear_buf
  ldx #0
  lda #0
.clear_buf_loop
  sta SPI_BUF_32,X
  inx
  cpx #32
  bne clear_buf_loop
  rts

.print_mem_buf
  LOAD_MSG mem_buf_msg
  jsr OSWRMSG
  ldx #0
.print_mem_buf_loop
  lda SPI_BUF_32,X
  jsr OSB2HEX
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  inx
  cpx #32
  bne print_mem_buf_loop
  lda #10
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  rts

\ ------------------------------------------------------------------------------
\ ---  OPTIONAL LIBRARY FUNCTION FILES
\ ------------------------------------------------------------------------------
; INCLUDE "../../LIB/math_uint8_mult.asm"
; INCLUDE "../../LIB/funcs_rtc_ds3234.asm"
;INCLUDE "../../LIB/funcs_spi65-dev.asm"
INCLUDE "../../LIB/funcs_spi_sram.asm"



.clear_buf_msg
  equs "Clearing buffer",10,0
.mem_buf_msg
  equs "Buffer: ",0
.read_mem_msg
  equs "Reading from memory",10,0
.set_buf_msg
  equs "Setting buffer contents",10,0
.page_mode_msg
  equs "Setting page mode",10,0
.write_mem_msg
  equs "Writing to memory...",10,0
.device_selected_msg
  equs "Device selected: ",0

.start_comm_msg
  equs "Starting operation...",10,0
.device_msg
  equs "Device: ",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/SRAM.EXE", header, endcode
