\ func_math_uint32_div16.asm

\ ------------------------------------------------------------------------------
\ ---  uint32_div16
\ ---  Divide a 32-bit unsigned integer by a 16-bit uint.
\ ---  Returns: 32-bit uint with quotient
\ ---			      32-bit uint with remainder (only bottom 16 bits significant)
\ ------------------------------------------------------------------------------
\ ON ENTRY: - UINT32_A/+3   - number to be divided
\           - UINT16_B/+1   - divisor
\ ON EXIT : - UINT32_RES/+3 - remainder
\           - UINT32_A/+3   - quotient
.uint32_div16
  ldx #3
.uint32_div16_clr_loop                  ; Ensure the result variable is cleared
  stz UINT32_RES,X
  dex
  bpl uint32_div16_clr_loop

  ldx #32                               ; There are 32 bits in dividend
.uint32_div16_shift_loop
  ; ----- SHIFT LEFT -----
  ; Over the course of 32 iterations, we shift the dividend, bit by bit, into
  ; the remainder. We do test subtractions against what is (so far) in the
  ; remainder. If test  a subtraction succeeds, the result is stored back in
  ; the remainder. Meanwhile, the variable that was originally
  ; the dividend is re-used to store the quotient.
  asl UINT32_A            ; LS bit of dividend replaced with 0
  rol UINT32_A + 1        ; Shift-left higher bytes via the Carry
  rol UINT32_A + 2
  rol UINT32_A + 3        ; Puts highest bit in Carry

  rol UINT32_RES          ; Top-most bit of dividend now in remainder as LSB.
  rol UINT32_RES + 1
  rol UINT32_RES + 2
  rol UINT32_RES + 3

  ; ----- TEST SUBTRACTIONS -----
  lda UINT32_RES                  ; Try subtracting low byte from remainder
  sec                             ; SEC gets set only here
  sbc UINT16_B                    ; Low byte of divisor
  tay                             ; Store the result for later

  lda UINT32_RES + 1              ; Now the high byte
  sbc UINT16_B + 1
  sta MATH_TMP_A                  ; Store for later

  lda UINT32_RES + 2              ; Now test third byte of remainder
  sbc #0                          ; Divisor is always 0. Leave the result in A

  bcc uint32_div16_nosub          ; Did subtraction succeed? If not, branch.

  sta UINT32_RES + 2              ; Subtraction worked. Store third byte result
  lda MATH_TMP_A                  ; Reload second byte result
  sta UINT32_RES + 1              ; and store it in remainder
  sty UINT32_RES                  ; And save result of low-byte sub in remainder
  inc UINT32_A                    ; Increment the quotient
.uint32_div16_nosub
  dex
  bne uint32_div16_shift_loop
  rts
