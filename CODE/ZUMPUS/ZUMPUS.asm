; Code for Zolatron 64 6502-based microcomputer.
;
; GitHub: https://github.com/mspeculatrix/Zolatron64/
; Blog: https://mansfield-devine.com/speculatrix/category/projects/zolatron/
;
; Written for the Beebasm assembler
; Assemble with:
; beebasm -v -i ZUMPUS.asm

CPU 1                               ; use 65C02 instruction set

INCLUDE "../../LIB/cfg_main.asm"
INCLUDE "../../LIB/cfg_page_0.asm"
; PAGE 1 is the STACK
INCLUDE "../../LIB/cfg_page_2.asm"
; PAGE 3 is used for STDIN & STDOUT buffers, plus indexes
INCLUDE "../../LIB/cfg_page_4.asm"
INCLUDE "../../LIB/cfg_VIAC.asm"

; CONSTANTS
NUM_ROOMS    = 20
NUM_STAPLES  = 5
NUM_LOCS     = 6

; ADDRESSES
RANDOM_LOCS  = $0500
PLAYER_LOC   = RANDOM_LOCS          ; 0500
ZUMPUS_LOC   = PLAYER_LOC + 1       ; 0501
BAT1_LOC     = ZUMPUS_LOC + 1       ; 0502
BAT2_LOC     = BAT1_LOC + 1         ; 0503
PIT1_LOC     = BAT2_LOC + 1         ; 0504
PIT2_LOC     = PIT1_LOC + 1         ; 0505
STAPLE_COUNT = PIT2_LOC + 1         ; 0506
P_CONN_ROOMS = STAPLE_COUNT + 1     ; 0507-0590
Z_CONN_ROOMS = P_CONN_ROOMS + 3     ; 050A-050C
FLAGS        = Z_CONN_ROOMS + 3     ; 050D
INPUT_NUM    = FLAGS + 1            ; 050E, 050F

; ERROR CODES
NOT_A_NUMBER = 1

; FLAGS
PIT_WARNING_ISSUED = %00000001
BAT_WARNING_ISSUED = %00000010


MACRO NEWLINE
  lda #CHR_LINEEND
  jsr OSWRCH
ENDMACRO

ORG USR_PAGE
.startcode
  sei             ; don't interrupt me yet
  cld             ; we don' need no steenkin' BCD
  ldx #$ff        ; set stack pointer to $01FF - only need to set the
  txs             ; LSB, as MSB is assumed to be $01

  lda #0
  sta PRG_EXIT_CODE
  cli

  stz VIAC_PORTA
  stz VIAC_PORTB

  lda #NUM_STAPLES
  sta STAPLE_COUNT

; Using Timer 1 for random numbers. Basically, this will run constantly in
; free-run mode, counting down constantly 59..0. So we're going to use it like
; a complex dice. Whenever we need to throw the dice, we just read the state of
; the counter. We'll only ever need to check the low byte. We can MOD the number
; by various factors - eg, 20 to get a random room number, 3 to get a random
; choice of connecting rooms.
  lda #%01000000		          ; Bit 7 off - don't need interrupts
  sta VIAC_IER
  lda #%01000000              ; Set timer to free-run mode
  sta VIAC_ACL			
  lda #59                     ; Start value
  sta VIAC_T1CL
  lda #0
  sta VIAC_T1CH		            ; starts timer running

.main
;  NEWLINE
;  LOAD_MSG start_msg
;  jsr OSWRMSG
;  NEWLINE

.init
; Randomise initial locations of player & threats
;  LOAD_MSG init_msg
;  jsr OSWRMSG
  NEWLINE
  ldy #0      ; Counter for number of locs we've set
.init_loop
  LOAD_MSG press_enter_msg
  jsr OSWRMSG
.init_loop_wait
  lda STDIN_STATUS_REG
  and #STDIN_NUL_RCVD_FLG
  bne init_set_loc
  jmp init_loop_wait
.init_set_loc
  ldx #20             ; MOD
  phy
  jsr roll_dice       ; Random number will be in A
  ply
  sta RANDOM_LOCS,Y
  stz STDIN_IDX        ; clear the input buffer
  lda STDIN_STATUS_REG ; reset the nul received flag
  and #STDIN_CLEAR_FLAGS
  sta STDIN_STATUS_REG
  ;check that this number not already used
  jsr init_check_unique
  lda FUNC_RESULT
  bne init_loop
  iny
  cpy #NUM_LOCS
  beq init_done
  jmp init_loop
.init_done
  lda #CHR_LINEEND
  jsr OSWRCH
  jmp start_play

.start_play
  jsr list_locs
  lda #235
  jsr uint8_decstr
  jsr OSWRSBUF
  NEWLINE
  jsr status_update

;  lda #'6'
;  sta STDIN_BUF
;  lda #'5'
;  sta STDIN_BUF+1
;  lda #'5'
;  sta STDIN_BUF+2
;  lda #'3'
;  sta STDIN_BUF+3
;  lda #'5'
;  sta STDIN_BUF+4
;  lda #0
;  sta STDIN_BUF+5
;  jsr get_decimal_input

;  lda MATH_TMP16+1
;  sta $0511
;  jsr OSB2HEX
;  jsr OSWRSBUF

;  lda MATH_TMP16
;  sta $0510
;  jsr OSB2HEX
;  jsr OSWRSBUF


;  ldy #59
;.loopback
;  tya
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  tya
;  ldx #20
;  jsr uint8_mod8
;  lda FUNC_RESULT
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  lda #' '
;  jsr OSWRCH
;  txa
;  jsr OSB2HEX
;  jsr OSWRSBUF
;  NEWLINE
;  dey
;  bmi done  
;  jmp loopback
;.done

.prog_end
  jmp OSSFTRST

INCLUDE "./zumpus_funcs.asm"
INCLUDE "./zumpus_data.asm"

.endcode

SAVE "../bin/ZUMPUS.BIN", startcode, endcode
