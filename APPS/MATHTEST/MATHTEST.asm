; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i TESTB.asm

MACRO PRT_ADDR addr
  lda #'$'
  jsr OSWRCH
  lda addr
  sta TMP_ADDR_A_L
  lda addr + 1
  sta TMP_ADDR_A_H
  jsr OSU16HEX
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  lda addr
  sta MATH_TMP_A
  lda addr + 1
  sta MATH_TMP_A+1
  jsr OSU16ISTR
  jsr OSWRSBUF
ENDMACRO

MACRO TESTING msg
  LOAD_MSG divider
  jsr OSWRMSG
  LOAD_MSG testing_msg
  jsr OSWRMSG
  LOAD_MSG msg
  jsr OSWRMSG
  NEWLINE
ENDMACRO

MACRO SHOW_BYTE value
  lda #'$'
  jsr OSWRCH
  lda #value
  jsr OSB2HEX
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  lda #' '
  jsr OSWRCH
  lda #value
  jsr OSB2ISTR
  jsr OSWRSBUF
ENDMACRO

CPU 1                               ; use 65C02 instruction set

NUM1 = $FF
NUM2 = $FF

NUM3 = $CEF0
NUM4 = $13

SUB1 = $3737
SUB2 = $1234

TIMES10_NUM = 13108

TEMP = $6000

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
  NEWLINE
  stz TEMP
  dec TEMP
  bmi test1
  jmp mainprog

.test1
  LOAD_MSG minus_flag
  jsr OSWRMSG

.mainprog

  \ ----- uint8_mult -----------------------------------------------------------
  TESTING uint8_mult_msg

  LOAD_MSG num1_msg
  jsr OSWRMSG
  SHOW_BYTE NUM1
  NEWLINE

  LOAD_MSG num2_msg
  jsr OSWRMSG
  SHOW_BYTE NUM2
  NEWLINE

  lda #NUM1
  ldx #NUM2
  jsr uint8_mult

  LOAD_MSG result_msg
  jsr OSWRMSG
  PRT_ADDR FUNC_RES_L
  NEWLINE

  \ ----- uint16_add -----------------------------------------------------------
  TESTING uint16_add_msg

  LOAD_MSG num1_msg
  jsr OSWRMSG
  lda #<SUB1
  sta MATH_TMP_A
  lda #>SUB1
  sta MATH_TMP_A+1
  PRT_ADDR MATH_TMP_A
  NEWLINE

  LOAD_MSG num2_msg
  jsr OSWRMSG
  lda #<SUB2
  sta MATH_TMP_B
  lda #>SUB2
  sta MATH_TMP_B+1
  PRT_ADDR MATH_TMP_B
  NEWLINE

  lda #<SUB1
  sta MATH_TMP_A
  lda #>SUB1
  sta MATH_TMP_A+1
  lda #<SUB2
  sta MATH_TMP_B
  lda #>SUB2
  sta MATH_TMP_B+1
  jsr uint16_add

  LOAD_MSG result_msg
  jsr OSWRMSG
  PRT_ADDR FUNC_RES_L
  NEWLINE

  \ ----- uint16_sub -----------------------------------------------------------
  TESTING uint16_sub_msg

  LOAD_MSG num1_msg
  jsr OSWRMSG
  lda #<SUB1
  sta MATH_TMP_A
  lda #>SUB1
  sta MATH_TMP_A+1
  PRT_ADDR MATH_TMP_A
  NEWLINE

  LOAD_MSG num2_msg
  jsr OSWRMSG
  lda #<SUB2
  sta MATH_TMP_B
  lda #>SUB2
  sta MATH_TMP_B+1
  PRT_ADDR MATH_TMP_B
  NEWLINE

  lda #<SUB1
  sta MATH_TMP_A
  lda #>SUB1
  sta MATH_TMP_A+1
  lda #<SUB2
  sta MATH_TMP_B
  lda #>SUB2
  sta MATH_TMP_B+1
  jsr uint16_sub

  LOAD_MSG result_msg
  jsr OSWRMSG
  PRT_ADDR FUNC_RES_L
  NEWLINE

  \ ----- uint16_div_uint8 -----------------------------------------------------------
  TESTING uint16_div_uint8_msg

  lda #<NUM3
  sta MATH_TMP_A
  lda #>NUM3
  sta MATH_TMP_A+1
  LOAD_MSG div_msg1
  jsr OSWRMSG
  PRT_ADDR MATH_TMP_A
  NEWLINE

  LOAD_MSG div_msg2
  jsr OSWRMSG
  SHOW_BYTE NUM4
  NEWLINE

  lda #<NUM3
  sta MATH_TMP_A
  lda #>NUM3
  sta MATH_TMP_A+1
  lda #NUM4
  jsr uint16_div_uint8

  LOAD_MSG div_result_msg
  jsr OSWRMSG
  PRT_ADDR FUNC_RES_L
  NEWLINE

  LOAD_MSG remainder_msg
  jsr OSWRMSG
  txa
  jsr OSB2HEX
  jsr OSWRSBUF
  NEWLINE


  \ ----- uint16_div -----------------------------------------------------------
  TESTING uint16_div_msg

  lda #<NUM3
  sta MATH_TMP_A
  lda #>NUM3
  sta MATH_TMP_A+1
  LOAD_MSG div_msg1
  jsr OSWRMSG
  PRT_ADDR MATH_TMP_A
  NEWLINE

  LOAD_MSG div_msg2
  jsr OSWRMSG
  lda #0
  sta MATH_TMP_B+1
  lda #NUM4
  sta MATH_TMP_B
  PRT_ADDR MATH_TMP_B
  NEWLINE
  lda #NUM4

  lda #<NUM3
  sta MATH_TMP_A
  lda #>NUM3
  sta MATH_TMP_A+1
  lda #0
  sta MATH_TMP_B+1
  lda #NUM4
  sta MATH_TMP_B
  jsr uint16_div

  lda FUNC_RES_L
  sta TMP_VAL
  ; FUNC_RES_L/H contains remainder
  ; MATH_TMP_A/+1 contains quotient

  LOAD_MSG div_result_msg
  jsr OSWRMSG
  PRT_ADDR MATH_TMP_A
  NEWLINE

  LOAD_MSG remainder_msg
  jsr OSWRMSG
  lda TMP_VAL
  sta FUNC_RES_L
  PRT_ADDR FUNC_RES_L
  NEWLINE

  \ ----- uint16_times10 -----------------------------------------------------------
  TESTING uint16_times10_msg

  LOAD_MSG mult_msg
  jsr OSWRMSG
  lda #<TIMES10_NUM
  sta MATH_TMP16
  lda #>TIMES10_NUM
  sta MATH_TMP16+1
  PRT_ADDR MATH_TMP16
  NEWLINE

  lda #<TIMES10_NUM
  sta MATH_TMP16
  lda #>TIMES10_NUM
  sta MATH_TMP16+1

  jsr uint16_times10

  bcs overflow
  jmp result_ok

.overflow
  lda FUNC_ERR
  beq carry_set               ; No error but carry set
  LOAD_MSG out_of_range_msg
  jsr OSWRMSG
  NEWLINE
  jmp prog_end
.carry_set
  LOAD_MSG carry_set_msg
  jsr OSWRMSG
  NEWLINE
.result_ok
  LOAD_MSG div_result_msg
  jsr OSWRMSG
  PRT_ADDR FUNC_RES_L
  NEWLINE

.prog_end
  jmp OSSFTRST

;INCLUDE "../../LIB/funcs_math.asm"
INCLUDE "../../LIB/math_uint8_div.asm"
INCLUDE "../../LIB/math_uint8_mult.asm"
INCLUDE "../../LIB/math_uint16_add.asm"
INCLUDE "../../LIB/math_uint16_div_uint8.asm"
INCLUDE "../../LIB/math_uint16_div.asm"
INCLUDE "../../LIB/math_uint16_sub.asm"
INCLUDE "../../LIB/math_uint16_times10.asm"

.num1_msg
  equs "First number : ", 0
.num2_msg
  equs "Second number: ", 0
.result_msg
  equs "Result       : ", 0

.div_msg1
  equs "Number to divide: ",0
.div_msg2
  equs "Divide by       : ",0
.div_result_msg
  equs "Result          : ",0

.mult_msg
  equs "Number          : ",0

.remainder_msg
  equs "Remainder       : ",0

.minus_flag
  equs "Branched on minus",10,0

.divider
  equs "----------",10,0
.testing_msg
  equs "Testing: ",0
.uint8_mult_msg
  equs "uint8_mult",0
.uint16_div_msg
  equs "uint16_div",0
.uint16_add_msg
  equs "uint16_add",0
.uint16_sub_msg
  equs "uint16_sub",0
.uint16_times10_msg
  equs "uint16_times10",0
.uint16_div_uint8_msg
  equs "uint16_div_uint8",0
.out_of_range_msg
  equs "Error: Out of range",0
.carry_set_msg
  equs "Carry set",0

.endtag
  equs "EOF",0
.endcode

SAVE "../bin/MATHTEST.EXE", header, endcode
