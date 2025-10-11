\ ------------------------------------------------------------------------------
\ ---  uint32_mult8
\ ---  Multiply an 32-bit unsigned integer by an 8-bit unsigned integer.
\ ---  Produces a 40-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - UINT32_A must contain the number to be multiplied
\			      - MATH_TMP_A must contain the multiplier.
\ ON EXIT : - UINT32_RES64 contains the result
.uint32_mult8
  lda UINT32_A + 3
  ldx MATH_TMP_A
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64
  sta UINT32_RES64
  lda FUNC_RES_H
  adc UINT32_RES64 + 1
  sta UINT32_RES64 + 1

  lda UINT32_A + 2
  ldx MATH_TMP_A
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 1
  sta UINT32_RES64 + 1
  lda FUNC_RES_H
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2

  lda UINT32_A + 1
  ldx MATH_TMP_A
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2
  lda FUNC_RES_H
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3

  lda UINT32_A
  ldx MATH_TMP_A
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3
  lda FUNC_RES_H
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4

  ; At this point we've stored the result big-endian
  ; Now convert to little endian
  ldx #7
.uint32_mult8_revloop_1
  lda UINT32_RES64,X
  pha
  dex
  bpl uint32_mult8_revloop_1
  ldx #7
.uint32_mult8_revloop_2
  pla
  sta UINT32_RES64,X
  dex
  bpl uint32_mult8_revloop_2
  rts
