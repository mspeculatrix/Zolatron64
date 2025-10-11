\ func_math_uint32_div8.asm

\ ------------------------------------------------------------------------------
\ ---  uint32_div8
\ ---  Divide a 32-bit unsigned integer by an 8-bit uint.
\ ---  Returns: 32-bit uint with quotient
\ ---			      32-bit uint with remainder (only bottom 8 bits significant)
\ ------------------------------------------------------------------------------
\ ON ENTRY: - UINT32_A/+3   - number to be divided
\           - MATH_TMP_A    - divisor
\ ON EXIT : - UINT32_RES/+3 - remainder
\           - UINT32_A/+3   - quotient
.uint32_div8
  ldx #3
.uint32_div8_clr_loop
  stz UINT32_RES,X
  dex
  bpl uint32_div8_clr_loop

  ldx #32                               ; There are 32 bits in dividend
.uint32_div8_loop
  ; ----- SHIFT LEFT -----
  asl UINT32_A            ; LS bit of dividend replaced with 0
  rol UINT32_A + 1
  rol UINT32_A + 2
  rol UINT32_A + 3

  rol UINT32_RES          ; Top-most bit of dividend now in remainder as LSB.
  rol UINT32_RES + 1      ; Over the course of 32 iterations, we gradually
  rol UINT32_RES + 2      ; Move the dividend into the remainder
  rol UINT32_RES + 3

  ; ----- TEST SUBTRACTIONS -----
  lda UINT32_RES                ; Try the low byte
  sec
  sbc MATH_TMP_A
  tay                           ; Store the result for later

  lda UINT32_RES + 1            ; Now second byte of remainder
  sbc #0                        ; Divisor is always 0. Leave the result in A

  bcc uint32_div8_nosub         ; Did subtraction succeed? If not, branch.
  sta UINT32_RES + 1            ; Subtraction worked. Store third byte result
  sty UINT32_RES                ; And save result of low-byte sub
  inc UINT32_A
.uint32_div8_nosub
  dex
  bne uint32_div8_loop
  rts
