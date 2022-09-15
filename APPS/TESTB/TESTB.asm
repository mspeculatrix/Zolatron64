; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

CPU 1                               ; use 65C02 instruction set

RAND_SEED = $6000
SEED_VAL = 65

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"

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
  equs "TESTB",0           ; @ $080D Short name, max 15 chars - nul terminated
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

  ;lda #SEED_VAL
  ;sta RAND_SEED

  cli

  jsr OSLCDCLS

.main
  LOAD_MSG welcome_msg
  jsr OSWRMSG
  lda #CHR_LINEEND
  jsr OSWRCH
  jsr OSLCDMSG

  LOAD_MSG second_msg
  jsr OSWRMSG
  jsr OSLCDMSG

  NEWLINE
  lda #245
  jsr OSB2ISTR
  jsr OSWRSBUF
  NEWLINE

  ldx #0
.seed_loop
  jsr rand8_seed
  lda RAND_SEED
  jsr OSB2ISTR
  jsr OSWRSBUF
  NEWLINE
  dex
  bne seed_loop

.prog_end
  jmp OSSFTRST

\ Changes RAND_SEED in an apparently random order, although the list is
\ actually always the same. They're just consecutive incrementing or
\ decrementing numbers.
.rand8_seed
  lda RAND_SEED
  beq rand8_seed_eor
  asl A
  beq rand8_seed_no_eor
  bcc rand8_seed_no_eor
.rand8_seed_eor
  eor #$1D
.rand8_seed_no_eor
  sta RAND_SEED
  rts

.welcome_msg
  equs "TEST B", 0

.second_msg
  equs "A second message", 0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTB.BIN", header, endcode
