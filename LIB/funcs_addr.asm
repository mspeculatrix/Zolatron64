\ ------------------------------------------------------------------------------
\ --- COMPARE_ADDR
\ --- Compare the 16-bit addresses in TMP_ADDR_A and TMP_ADDR_B
\ ------------------------------------------------------------------------------
\ ON ENTRY: - 16-bit addresses in TMP_ADDR_A and TMP_ADDR_B. We're assuming
\             that addr B is higher than addr A.
\ ON EXIT : - FUNC_RESULT contains comparison - LESS_THAN if A lower than B,
\             EQUAL if same, MORE_THAN if higher.
\ A - O     X - n/a     Y - n/a
.compare_addr
  lda TMP_ADDR_A_H                ; Test high bytes first
  cmp TMP_ADDR_B_H
  bcc compare_addr_less           ; A is less than B
  bne compare_addr_more           ; A is more than B
  lda TMP_ADDR_A_L                ; Only if high bytes are equal do we need to
  cmp TMP_ADDR_B_L                ; test the low bytes
  bcc compare_addr_less
  bne compare_addr_more
  lda #EQUAL				              ; A = B
  jmp compare_addr_end
.compare_addr_less
  lda #LESS_THAN			            ; A < B
  jmp compare_addr_end
.compare_addr_more
  lda #MORE_THAN			            ; A > B
.compare_addr_end
  sta FUNC_RESULT
  rts
