\ ------------------------------------------------------------------------------
\ --- CMD: JMP  :  JUMP TO ADDRESS
\ ------------------------------------------------------------------------------
\ Jump to a specified address and execute from there.
.cmdprcJMP
  jsr read_hex_addr         ; Read address. Puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcJMP_fail
  ldx #$ff                  ; Reset stack pointer
  txs
  stz STDIN_IDX             ; Reset RX buffer index
  jmp (FUNC_RES_L)          ; Make the jump
.cmdprcJMP_fail
  jmp cmdprc_fail 
