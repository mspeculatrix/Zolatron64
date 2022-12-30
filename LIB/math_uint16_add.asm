\ math_uint16_add.asm

\ ------------------------------------------------------------------------------
\ ---  uint16_add
\ ---  Add two 16-bit numbers. Produces 16-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: Numbers must be in MATH_TMP_A/+1 and MATH_TMP_B/+1
\ ON EXIT : - Result is in FUNC_RES_L/H
\           - Carry bit set in case of overflow
.uint16_add
  stz TMP_VAL                       ; We'll use this for the carry
  stz FUNC_RES_L                    ; Ensure result is cleared out
  stz FUNC_RES_H
  clc
  lda MATH_TMP_A                    ; Add low bytes
  adc MATH_TMP_B
  sta FUNC_RES_L                    ; And stash the result
  bcc uint16_add_highbyte           ; If no carry, go to next section
  inc TMP_VAL                       ; Otherwise, use this to contain carry
.uint16_add_highbyte
  clc
  lda MATH_TMP_A+1                  ; Add the high bytes
  adc MATH_TMP_B+1
  adc TMP_VAL                       ; Also add the carry, if any
  sta FUNC_RES_H                    ; Stash the result
  rts
