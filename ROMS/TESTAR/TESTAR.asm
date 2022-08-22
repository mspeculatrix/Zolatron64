; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTAR.asm

CPU 1                               ; use 65C02 instruction set

BARLED = $0230				      ; for the bar LED display
BARLED_L = BARLED
BARLED_H = BARLED + 1

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"

ORG EXTMEM_LOC
.header                     ; HEADER INFO
  jmp startprog             ;
  equw header               ; @ $0803 Entry address
  equw reset                ; @ $0805 Reset address
  equw endcode              ; @ $0807 Addr of first byte after end of program
  equb "P"
  equs 0,0,0                ; -- Reserved for future use --
  equs "TESTAR",0           ; @ $080D Short name, max 15 chars - nul terminated
.version_string
  equs "1.0",0              ; Version string - nul terminated

.startprog
.reset
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE
  cli

  jsr OSLCDCLS

.main
  lda #'A'
  jsr OSLCDCH
  jsr OSWRCH
  lda #'B'
  jsr OSLCDCH
  jsr OSWRCH
  lda #'C'
  jsr OSLCDCH
  jsr OSWRCH
  lda #' '
  jsr OSWRCH

  jsr OSWRSBUF
  lda #CHR_LINEEND
  jsr OSWRCH

  LOAD_MSG start_msg
  jsr OSWRMSG
  lda #CHR_LINEEND
  jsr OSWRCH
  jsr OSLCDMSG

  LOAD_MSG second_msg
  jsr OSWRMSG
  jsr OSLCDMSG

.prog_end
  jmp OSSFTRST

.start_msg
  equs "Test A", 0

.second_msg
  equs "Hello world! ROM version.", 0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTAR.BIN", header, endcode
