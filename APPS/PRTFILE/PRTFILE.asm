; Code for Zolatron 64 6502-based microcomputer.
;
; Program to test out the printing functions of ZolaDOS.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i PRT.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
;INCLUDE "../../LIB/cfg_parallel.asm"
INCLUDE "../../LIB/cfg_2x16_lcd.asm"
INCLUDE "../../LIB/cfg_prt.asm"

ORG USR_PAGE
.header                     ; HEADER INFO
  INCLUDE "../../LIB/header_std.asm"
  equb "E"
  equs 0,0,0              ; -- Reserved for future use --
  equs "PRT",0            ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "0.1",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; Don't interrupt me yet
  cld             ; Don't want BCD
  ldx #$FF        ; Set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01
  stz PRG_EXIT_CODE
  cli

.main
  jsr OSPRTINIT



.filename_prompt
  equs "Name of file to print: ",0

.another_file_prompt
  equs "Do you want to print another file (y/n)? ",0

.quit_msg
  equs "All done.",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/PRTFILE.BIN", header, endcode
