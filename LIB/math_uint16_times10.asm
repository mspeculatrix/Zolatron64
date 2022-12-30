\ math_uint16_times10

\ ------------------------------------------------------------------------------
\ --- uint16_times10
\ --- Multiply 16-bit integer by 10.
\ ------------------------------------------------------------------------------
\ Multiply 16-bit number by 10
\ ON ENTRY: - 16-bit unsigned number in MATH_TMP16/+1
\ ON EXIT : - 16-bit unsigned number in FUNC_RES_L/H
\           - FUNC_ERR = 1 if out of range, 0 for okay
\           - The result might conceivably stay in range right to the the final
\             x2 multiplication. It could be useful to know that, so when using
\             This function, test both for the carry and the value of FUNC_ERR.
\             If X is set, then the result is unusable. But if it's not, then
\             the result is still out of range if the Carry is set. In this
\             case, the actul result is 65536 + whatever is in FUNC_RES_L/H.
.uint16_times10
  pha
  stz FUNC_ERR
  lda MATH_TMP16        ; Start with Result = Value
  sta FUNC_RES_L
  lda MATH_TMP16+1
  sta FUNC_RES_H
  asl FUNC_RES_L        ; 0 shifted into bit 0; bit 7 into Carry
  rol FUNC_RES_H        ; Result = 2*MATH_TMP16
  asl FUNC_RES_L        ; Multiply by x2 again, to get x4
  rol FUNC_RES_H
  clc
  lda MATH_TMP16        ; Now add the original value to result to get x5
  adc FUNC_RES_L
  sta FUNC_RES_L
  lda MATH_TMP16+1      ; Any Carry from previous addition will be included
  adc FUNC_RES_H
  sta FUNC_RES_H        ; Result = 5x Value
  bcs uint16_times10_err
  asl FUNC_RES_L        ; Now double one last time to get x10
  rol FUNC_RES_H
  jmp uint16_times10_done
.uint16_times10_err
  inc FUNC_ERR
.uint16_times10_done
  pla
  rts
