\ ------------------------------------------------------------------------------
\ ---  uint16_div_uint8
\ ---  Divide a 16-bit unsigned integer by an 8 bit unsigned integer.
\ ---  Returns a 16-bit uint.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Number to be divided must be in MATH_TMP_A
\           - Divisor must be in A
\ ON EXIT : - Result in FUNC_RES_L/H
\           - Remainder in X
\ *** THIS IS VERY SLOW ***
.uint16_div_uint8
  stz FUNC_RES_L                       ; Zero-out result register
  stz FUNC_RES_H
  sta MATH_TMP_B                          ; Copy divisor
.uint16_div_uint8_loop
  lda MATH_TMP_A                       ; Load current value
  tax                                  ; save in X as remainder
  sec
  sbc MATH_TMP_B                          ; Subtract divisor
  sta MATH_TMP_A                       ; Re-save value for next time
  bcs uint16_div_uint8_count           ; If carry not affected, inc count & loop
  lda MATH_TMP_A+1
  beq uint16_div_uint8_done            ; Is it already at 0?
  dec MATH_TMP_A+1                     ; If not, decrement high byte
.uint16_div_uint8_count                ; Increment counter
  inc FUNC_RES_L                       ; Increment our result
  bne uint16_div_uint8_count_next      ; Did low byte roll over?
  inc FUNC_RES_H                       ; If so, increment high byte
.uint16_div_uint8_count_next
  jmp uint16_div_uint8_loop            ; And go again
.uint16_div_uint8_done
  rts
