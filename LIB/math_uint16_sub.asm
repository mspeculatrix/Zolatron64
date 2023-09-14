\ math_uint16_sub.asm

\ ------------------------------------------------------------------------------
\ ---  uint16_sub
\ ---  Subtract one 16-bit number from another. Produces 16-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: Numbers must be in MATH_TMP_A/+1 and MATH_TMP_B/+1
\ ON EXIT : - Result is in FUNC_RES_L/H
\           - Carry bit set if okay, clear if underflow
.uint16_sub
  sec
  lda MATH_TMP_A
  sbc MATH_TMP_B
  sta FUNC_RES_L
  lda MATH_TMP_A+1
  sbc MATH_TMP_B+1
  sta FUNC_RES_H
  rts
