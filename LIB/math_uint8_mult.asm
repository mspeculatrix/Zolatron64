\ math_uint8_mult.asm

\ ------------------------------------------------------------------------------
\ ---  uint8_mult
\ ---  Multiply an 8-bit unsigned integer by another 8-bit unsigned integer.
\ ---  Produces a 16-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A must contain the number to be multiplied
\			      - X must contain the multiplier.
\ ON EXIT : - FUNC_RES_L/H contains the result
.uint8_mult
  sta MATH_TMP_A
  stx MATH_TMP_B
  lda #0                          ; Initialize RESULT to 0
  ldx #8                          ; There are 8 bits in NUM2
.uint8_mult_L1
  lsr MATH_TMP_B                  ; Get low bit of NUM2
  bcc uint8_mult_L2               ; 0 or 1?
  clc                             ; If 1, add NUM1
  adc MATH_TMP_A
.uint8_mult_L2
  ror A                           ; 'Stairstep' shift (catching carry from add)
  ror FUNC_RES_L
  dex
  bne uint8_mult_L1
  sta FUNC_RES_H
  rts
