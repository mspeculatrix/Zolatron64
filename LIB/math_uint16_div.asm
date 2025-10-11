\ func_math_uint16_div.asm

\ ------------------------------------------------------------------------------
\ ---  uint16_div
\ ---  Divide a 16-bit unsigned integer by another 16-bit uint.
\ ---  Returns 16-bit uints containing quotient and remainder.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - MATH_TMP_A should contain number to be divided
\           - MATH_TMP_B/+1 must contain divisor
\ ON EXIT : - FUNC_RES_L/H contains remainder
\           - MATH_TMP_A/+1 contains quotient
.uint16_div
  stz FUNC_RES_L                       ; Zero-out result register
  stz FUNC_RES_H
  ldx #16                              ; There are 16 bits in NUM1
.uint16_div_loop
  ; ASL - 0 is shifted into bit 0; original bit 7 is shifted into the Carry
  asl MATH_TMP_A
  ; ROL - Carry shifted into bit 0; original bit 7 shifted into Carry.
  rol MATH_TMP_A+1

  rol FUNC_RES_L
  rol FUNC_RES_H

  lda FUNC_RES_L
  sec                           ; Trial subtraction
  sbc MATH_TMP_B
  tay
  lda FUNC_RES_H
  sbc MATH_TMP_B+1
  bcc uint16_div_nosub          ; Did subtraction succeed?
  sta FUNC_RES_H                ; If yes, save it
  sty FUNC_RES_L
  inc MATH_TMP_A                ; and record a 1 in the quotient
.uint16_div_nosub
  dex
  bne uint16_div_loop
  rts
