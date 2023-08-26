\ ------------------------------------------------------------------------------
\ ---  uint32_mult32
\ ---  Multiply an 32-bit unsigned integer by another 32-bit unsigned integer.
\ ---  Produces a 64-bit result.
\ ------------------------------------------------------------------------------
\ ON ENTRY: - UINT32_A must contain the number to be multiplied
\			      - UINT32_B must contain the multiplier.
\ ON EXIT : - UINT32_RES64 contains the result
.uint32_mult32
  lda UINT32_A + 3
  ldx UINT32_B + 3
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64
  sta UINT32_RES64
  lda FUNC_RES_H
  adc UINT32_RES64 + 1
  sta UINT32_RES64 + 1

  lda UINT32_A + 3
  ldx UINT32_B + 2
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 1
  sta UINT32_RES64 + 1
  lda FUNC_RES_H
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2

  lda UINT32_A + 3
  ldx UINT32_B + 1
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2
  lda FUNC_RES_H
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3

  lda UINT32_A + 3
  ldx UINT32_B
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3
  lda FUNC_RES_H
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4

  lda UINT32_A + 2
  ldx UINT32_B + 3
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 1
  sta UINT32_RES64 + 1
  lda FUNC_RES_H
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2

  lda UINT32_A + 2
  ldx UINT32_B + 2
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2
  lda FUNC_RES_H
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3

  lda UINT32_A + 2
  ldx UINT32_B + 1
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3
  lda FUNC_RES_H
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4

  lda UINT32_A + 2
  ldx UINT32_B
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4
  lda FUNC_RES_H
  adc UINT32_RES64 + 5
  sta UINT32_RES64 + 5

  lda UINT32_A + 1
  ldx UINT32_B + 3
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 2
  sta UINT32_RES64 + 2
  lda FUNC_RES_H
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3

  lda UINT32_A + 1
  ldx UINT32_B + 2
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3
  lda FUNC_RES_H
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4

  lda UINT32_A + 1
  ldx UINT32_B + 1
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4
  lda FUNC_RES_H
  adc UINT32_RES64 + 5
  sta UINT32_RES64 + 5

  lda UINT32_A + 1
  ldx UINT32_B
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 5
  sta UINT32_RES64 + 5
  lda FUNC_RES_H
  adc UINT32_RES64 + 6
  sta UINT32_RES64 + 6

  lda UINT32_A
  ldx UINT32_B + 3
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 3
  sta UINT32_RES64 + 3
  lda FUNC_RES_H
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4

  lda UINT32_A
  ldx UINT32_B + 2
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 4
  sta UINT32_RES64 + 4
  lda FUNC_RES_H
  adc UINT32_RES64 + 5
  sta UINT32_RES64 + 5

  lda UINT32_A
  ldx UINT32_B + 1
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 5
  sta UINT32_RES64 + 5
  lda FUNC_RES_H
  adc UINT32_RES64 + 6
  sta UINT32_RES64 + 6

  lda UINT32_A
  ldx UINT32_B
  jsr uint8_mult ; FUNC_RES_L/H contains the result
  lda FUNC_RES_L
  clc
  adc UINT32_RES64 + 6
  sta UINT32_RES64 + 6
  lda FUNC_RES_H
  adc UINT32_RES64 + 7
  sta UINT32_RES64 + 7

  ; At this point we've stored the result big-endian
  ; Now convert to little endian
  ldx #7
.reverse_loop_1
  lda UINT32_RES64,X
  pha
  dex
  bpl reverse_loop_1
  ldx #7
.reverse_loop_2
  pla
  sta UINT32_RES64,X
  dex
  bpl reverse_loop_2
  rts
