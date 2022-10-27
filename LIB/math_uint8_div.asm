\ math_uint8_div.asm

\ *** Replaces uint8_mod in funcs_math.asm ***

\ ------------------------------------------------------------------------------
\ ---  uint8_div
\ ---  MOD/DIV an 8-bit unsigned int by another 8-bit uint
\ ------------------------------------------------------------------------------
\ ON ENTRY: - A must contain the dividend - the number to be modded
\			      - X must contain the divisor
\ ON EXIT : - FUNC_RESULT contains remainder
\           - X contains quotient (number of divisions. X=0 if num < divisor)
\ A - O
\ X - O
\ Y - n/a
.uint8_div
  stx TMP_VAL
  ldx #0
.uint8_div_loop
  sta FUNC_RESULT
  sec
  sbc TMP_VAL
  bcc uint8_div_result   ; We've gone too far
  inx
  jmp uint8_div_loop
.uint8_div_result
  rts
