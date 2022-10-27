\ math_uint16_times10

\ ------------------------------------------------------------------------------
\ --- uint16_times10
\ --- Multiply 16-bit integer by 10.
\ ------------------------------------------------------------------------------
\ Multiply 16-bit number by 10
\ ON ENTRY: - 16-bit unsigned number in MATH_TMP16/+1
\ ON EXIT : - 16-bit unsigned number in FUNC_RES_L/H
.uint16_times10
  lda MATH_TMP16       ;Start with RESULT = MATH_TMP16
  sta FUNC_RES_L
  lda MATH_TMP16+1
  sta FUNC_RES_H
  asl FUNC_RES_L
  rol FUNC_RES_H  ;RESULT = 2*MATH_TMP16
  asl FUNC_RES_L
  rol FUNC_RES_H  ;RESULT = 4*MATH_TMP16
  clc
  lda MATH_TMP16
  adc FUNC_RES_L
  sta FUNC_RES_L
  lda MATH_TMP16+1
  adc FUNC_RES_H
  sta FUNC_RES_H  ;RESULT = 5*MATH_TMP16
  asl FUNC_RES_L
  rol FUNC_RES_H  ;RESULT = 10*MATH_TMP16
  lda FUNC_RES_L
  sta MATH_TMP16
  lda FUNC_RES_H
  sta MATH_TMP16+1
  rts
