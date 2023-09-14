\ func_math_uint32_add.asm

\ *** NB *** Do you really need a function for this? Probably better to do
\ in situ.

\ ------------------------------------------------------------------------------
\ ---  uint32_add
\ ---  Add two 32-bit unsigned integers
\ ---  Returns: 32-bit uint
\ ------------------------------------------------------------------------------
\ ON ENTRY: - UINT32_A/+3   - numbers to be added
\			        UINT32_B/+3
\ ON EXIT : - UINT32_RES/+3 - sum
.uint32_add
  ldx #0
  clc
.uint32_add_loop
  lda UINT32_A,X
  adc UINT32_B,X
  sta UINT32_RES,X
  inx
  cpx #4
  bne uint32_add_loop
  rts
