; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

MACRO PRT_ADDR addr
  lda addr
  sta TMP_ADDR_A_L
  lda addr + 1
  sta TMP_ADDR_A_H
  jsr OSU16HEX
  jsr OSWRSBUF
ENDMACRO



CPU 1                               ; use 65C02 instruction set

NUM = $545E ; 21598
;NUM = $0

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_user_port.asm"

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

  stz PRG_EXIT_CODE

  cli

.main

  jsr carry_set
  jsr divisor_smaller
  sec
  lda #$AA
  sbc #$99
  bcc carry_clear1
  jsr carry_set
  jmp next1
.carry_clear1
  jsr carry_clear

.next1
  lda #'-'
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  jsr carry_clear
  jsr divisor_smaller
  clc
  lda #$AA
  sbc #$99
  bcc carry_clear2
  jsr carry_set
  jmp next2
.carry_clear2
  jsr carry_clear

.next2
  lda #'-'
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  jsr carry_set
  jsr divisor_bigger
  sec
  lda #$AA
  sbc #$BB
  bcc carry_clear3
  jsr carry_set
  jmp next3
.carry_clear3
  jsr carry_clear

.next3
  lda #'-'
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  jsr carry_clear
  jsr divisor_bigger
  clc
  lda #$AA
  sbc #$BB
  bcc carry_clear4
  jsr carry_set
  jmp next4
.carry_clear4
  jsr carry_clear

.next4
  lda #'-'
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  jsr carry_set
  jsr divisor_same
  sec
  lda #$AA
  sbc #$AA
  bcc carry_clear5
  jsr carry_set
  jmp next5
.carry_clear5
  jsr carry_clear

.next5
  lda #'-'
  jsr OSWRCH
  lda #10
  jsr OSWRCH
  jsr carry_clear
  jsr divisor_same
  clc
  lda #$AA
  sbc #$AA
  bcc carry_clear6
  jsr carry_set
  jmp next6
.carry_clear6
  jsr carry_clear

.next6
  jmp prog_end

.divisor_same
  LOAD_MSG divisor_same_msg
  jsr OSWRMSG
  rts


.divisor_bigger
  LOAD_MSG divisor_bigger_msg
  jsr OSWRMSG
  rts

.divisor_smaller
  LOAD_MSG divisor_smaller_msg
  jsr OSWRMSG
  rts

.carry_set
  LOAD_MSG carry_set_msg
  jsr OSWRMSG
  rts

.carry_clear
  LOAD_MSG carry_clear_msg
  jsr OSWRMSG
  rts

.prog_end
  jmp OSSFTRST



;INCLUDE "../../LIB/funcs_math.asm"
;INCLUDE "../../LIB/math_uint16_div.asm"

.carry_set_msg
  equs "Carry Set",10,0
.carry_clear_msg
  equs "Carry Clear",10,0
.divisor_smaller_msg
  equs "Divisor smaller", 10, 0
.divisor_bigger_msg
  equs "Divisor bigger",10,0
.divisor_same_msg
  equs "Divisor same",10,0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/TESTB.EXE", header, endcode
