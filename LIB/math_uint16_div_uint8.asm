\ ------------------------------------------------------------------------------
\ ---  uint16_div_uint8
\ ---  Divide a 16-bit unsigned integer by an 8 bit unsigned integer.
\ ---  Returns a 16-bit uint.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - Number to be divided must be in MATH_TMP_A/+1
\           - Divisor must be in A
\ ON EXIT : - Result in FUNC_RES_L/H
\           - Remainder in X
\ Using MATH_TMP_B for shift operations.
\ This works, but might be just as easy to use uint16_div
\ Based on Ben Eater video: https://www.youtube.com/watch?v=v3-a-zqKfgA

.uint16_div_uint8
  sta TMP_VAL                   ; Our divisor
  ldy #16                       ; Number of rotations we need to do.
  stz MATH_TMP_B                ; Use this for the high 16 bits for rotation
  stz MATH_TMP_B+1              ; operations
  lda MATH_TMP_A                ; Move our number to be divided into
  sta FUNC_RES_L                ; FUNC_RES_L/H, because that's where it needs
  lda MATH_TMP_A+1              ; to end up anyway.
  sta FUNC_RES_H
  clc
 .uint16_div_uint8_loop
  ; Roll all 32 bits to the left, shifting Carry from bit 31 to bit 0
  ; ROL - Carry shifted into bit 0; original bit 7 shifted into Carry.
  rol FUNC_RES_L
  rol FUNC_RES_H
  rol MATH_TMP_B
  rol MATH_TMP_B+1
  lda MATH_TMP_B                ; Now test lower byte of upper 16
  sec
  sbc TMP_VAL                   ; Trial subtraction of divisor
  tax                           ; Store result temporarily
  lda MATH_TMP_B+1
  sbc #0
  bcc uint16_div_uint8_next     ; Borrow happened, subtraction failed
  sta MATH_TMP_B+1              ; Replace lower byte of upper 16 with result
  stx MATH_TMP_B
.uint16_div_uint8_next
  dey                           ; Decrement counter
  bne uint16_div_uint8_loop
  rol FUNC_RES_L                ; One final roll to get Carry bit into position
  rol FUNC_RES_H
.uint16_div_uint8_done
  ldx MATH_TMP_B                ; Lower byte of upper 16 holds remainder
  rts
