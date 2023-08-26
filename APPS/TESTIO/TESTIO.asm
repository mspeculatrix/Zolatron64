; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_uart_SC28L92.asm"

ORG USR_START
.header                     ; HEADER INFO
  jmp startprog             ;
  equb "E"                  ; Designate executable file
  equb <header              ; Entry address
  equb >header
  equb <reset               ; Reset address
  equb >reset
  equb <endcode             ; Addr of first byte after end of program
  equb >endcode
  equs 0,0,0                ; -- Reserved for future use --
.prog_name
  equs "TESTIO",0           ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  stz PRG_EXIT_CODE

  cli

.main
  LOAD_MSG welcome_msg
  jsr OSWRMSG
  lda #CHR_LINEEND
  jsr OSWRCH

  ldy #2                        ; Loop counter
  ldx #SC28L92_OP2               ; Start with pin 2
  lda #1                        ; Write a 1 to it
  jsr OSWROP
.loop
  LOAD_MSG enter_msg
  jsr OSWRMSG
  jsr OSGETKEY
  lda #0                        ; Write a 0 to the current pin
  jsr OSWROP
  txa                           ; Increase the pin number
  asl A
  tax
  lda #1
  jsr OSWROP
  iny
  cpy #6
  bne loop


.prog_end
  jmp OSSFTRST


\ --- DATA ---------------------------------------------------------------------
.welcome_msg
  equs "TESTIO - experimenting with I/O code", 0

.enter_msg
  equs "Type any key > ",0


.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTIO.EXE", header, endcode
