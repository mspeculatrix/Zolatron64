; FUNCTIONS: MATHS & Numbers -- funcs_math.asm ---------------------------------
; v01 - 25 Nov 2021

.subtract_16
  ; subtracts a 16-bit number stored in TMP_ADDR_A from another 16-bit value
  ; in TMP_ADDR_B.
  pha
  sec
  lda TMP_ADDR_B
  sbc TMP_ADDR_A
  sta FUNC_RES_L
  lda TMP_ADDR_B + 1
  sbc TMP_ADDR_A + 1
  sta FUNC_RES_H
  pla
  rts
  