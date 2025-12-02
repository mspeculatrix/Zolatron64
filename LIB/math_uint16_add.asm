\ math_uint16_add.asm

\ ------------------------------------------------------------------------------
\ ---  uint16_add
\ ---  Add two 16-bit numbers. Produces 16-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: Numbers must be in MATH_TMP_A/+1 and MATH_TMP_B/+1
\ ON EXIT : - Result is in FUNC_RES_L/H
\           - Carry bit set in case of overflow
.uint16_add
  clc
  lda MATH_TMP_A
  adc MATH_TMP_B
  sta FUNC_RES_L
  lda MATH_TMP_A + 1
  adc MATH_TMP_B + 1
  sta FUNC_RES_H
  rts
