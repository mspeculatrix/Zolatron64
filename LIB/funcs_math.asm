\ MATHS & Numbers -- funcs_math.asm --------------------------------------------

\ ------------------------------------------------------------------------------
\ ---  uint8_mod8
\ ---  MOD/DIV an 8-bit number by another 8-bit number
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A must contain the dividend - the number to be modded
\			      - X must contain the divisor
\ ON EXIT : - FUNC_RESULT contains remainder
\           - X contains quotient (number of divisions. X=0 if num < divisor) 
.uint8_mod8
  stx TMP_VAL
  ldx #0
.uint8_mod8_loop
  sta FUNC_RESULT
  sec
  sbc TMP_VAL
  bcc uint8_mod8_result   ; We've gone too far
  inx
  jmp uint8_mod8_loop
.uint8_mod8_result
  rts

\ ------------------------------------------------------------------------------
\ --- uint16_times10
\ --- Multiply 16-bit integer by 10.
\ ------------------------------------------------------------------------------
\ ON ENTRY: 16-bit unsigned number in MATH_TMP16, MATH_TMP16+1
\ ON EXIT : - 16-bit unsigned number in MATH_TMP16, MATH_TMP16+1
\           - Carry bit will be set if 16-bit overflow occurred.
\           - Error code in FUNC_ERR
\ ------------------------------------------------------------------------------
.uint16_times10
  phx
  ldx #1                                ; Multiply high byte first
.uint16_times10_outer
  ldy #0
  lda MATH_TMP16,X
  sta $0512,X
  sta TMP_VAL
.uint16_times10_loop
  clc
  adc TMP_VAL
  bcs uint16_times10_carry
  jmp uint16_times10_next_inc
.uint16_times10_carry
  cpx #0
  bne uint16_times10_next_inc       ; We're in the high byte, so skip...
  inc MATH_TMP16+1
.uint16_times10_next_inc
  iny
  cpy #9
  beq uint16_times10_next_byte
  jmp uint16_times10_loop
.uint16_times10_next_byte
  sta MATH_TMP16,X
  cpx #0
  beq uint16_times10_done
  dex
  jmp uint16_times10_outer
.uint16_times10_done
  plx
  rts


;.subtract16u
  ; subtracts a 16-bit number stored in INT16uB from another 16-bit value
  ; in INT16uA.
;  pha
;  sec
;  lda INT16uA
;  sbc INT16uB
;  sta FUNC_RES_L
;  lda INT16uA + 1
;  sbc INT16uB + 1
;  sta FUNC_RES_H
;  pla
;  rts

\ ------------------------------------------------------------------------------
\ --- compate_tmp_addr
\ --- Compare the 16-bit addresses in TMP_ADDR_A and TMP_ADDR_B
\ ------------------------------------------------------------------------------
\ ON ENTRY: - 16-bit addresses in TMP_ADDR_A and TMP_ADDR_B. We're assuming
\             that addr B is higher than addr A.
\ ON EXIT : - FUNC_RESULT contains comparison - LESS_THAN if A lower than B,
\             EQUAL if same, MORE_THAN if higher.
\ ------------------------------------------------------------------------------
.compare_tmp_addr
  lda TMP_ADDR_A_H                ; Test high bytes first
  cmp TMP_ADDR_B_H
  bcc compare_tmp_addr_less       ; A is less than B
  bne compare_tmp_addr_more       ; A is more than B
  lda TMP_ADDR_A_L                ; Only if high bytes are equal do we need to
  cmp TMP_ADDR_B_L                ; test the low bytes
  bcc compare_tmp_addr_less
  bne compare_tmp_addr_more
  lda #EQUAL				          ; A = B
  jmp compare_tmp_addr_end
.compare_tmp_addr_less
  lda #LESS_THAN			        ; A < B
  jmp compare_tmp_addr_end
.compare_tmp_addr_more
  lda #MORE_THAN			        ; A > B
.compare_tmp_addr_end
  sta FUNC_RESULT
  rts

;.compare16u                 ; Compare two 16-bit unsigned values
;  pha
;  lda INT16uA+1
;  cmp INT16uB+1
;  bcc compare16u_less_than
;  bne compare16u_more_than
;  lda INT16uA
;  cmp INT16uB
;  bcc compare16u_less_than
;  bne compare16u_more_than
;  lda #EQUAL				          ; A = B
;  jmp compare16u_end
;.compare16u_less_than
;  lda #LESS_THAN			        ; A < B
;  jmp compare16u_end
;.compare16u_more_than
;  lda #MORE_THAN			        ; A > B
;.compare16u_end
;  sta FUNC_RESULT
;  pla
;  rts

;.compare32u                 ; Compare two 32-bit unsigned values
;  pha
;  lda INT32uA+3
;  cmp INT32uB+3
;  bcc compare32u_less_than  ; NUMA < NUMB
;  bne compare32u_more_than	; if NUMA+3 <> NUMB+3 then NUMA > NUMB 
;  lda INT32uA+2
;  cmp INT32uB+2
;  bcc compare32u_less_than
;  bne compare32u_more_than
;  lda INT32uA+1
;  cmp INT32uB+1
;  bcc compare32u_less_than
;  bne compare32u_more_than
;  lda INT32uA
;  cmp INT32uB
;  bcc compare32u_less_than
;  bne compare32u_more_than
;  lda #EQUAL				          ; A = B
;  jmp compare32u_end
;.compare32u_less_than
;  lda #LESS_THAN			        ; A < B
;  jmp compare32u_end
;.compare32u_more_than
;  lda #MORE_THAN			        ; A > B
;.compare32u_end
;  sta FUNC_RESULT
;  pla
;  rts

