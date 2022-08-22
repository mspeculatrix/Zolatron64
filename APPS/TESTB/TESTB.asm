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

ORG USR_PAGE
.header                     ; HEADER INFO
  jmp startprog             ;
  equw header               ; @ $0803 Entry address
  equw reset                ; @ $0805 Reset address
  equw endcode              ; @ $0807 Addr of first byte after end of program
  equb 'P'
  equs 0,0,0                ; -- Reserved for future use --
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

  LOAD_MSG welcome_msg
  jsr OSWRMSG
  lda #CHR_LINEEND
  jsr OSWRCH
  jsr OSLCDMSG

  LOAD_MSG second_msg
  jsr OSWRMSG
  jsr OSLCDMSG
;  inc BARLED_L
;  bne main_loop
;  inc BARLED_H
;.main_loop
;  lda BARLED_L
;  sta VIAC_PORTA
;  lda BARLED_H
;  sta VIAC_PORTB
;  cmp #255
;  beq chk_lowbyte
;.continue
;  jsr barled_delay
;  jmp main
;.chk_lowbyte
;  lda BARLED_L
;  cmp #255
;  beq prog_end
;  jmp continue

.prog_end
  jmp OSSFTRST

;.barled_delay
;  ldx #2
;.barled_delay_x_loop
;  ldy #255
;.barled_delay_y_loop
;  nop
;  dey
;  bne barled_delay_y_loop
;  dex
;  bne barled_delay_x_loop
;  rts

.welcome_msg
  equs "This is a new test", 0

.second_msg
  equs "A second message", 0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTB.BIN", header, endcode
