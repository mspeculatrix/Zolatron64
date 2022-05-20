;-------------------------------------------------------------------------------
; --- CMD: JMP                                                                ---
;-------------------------------------------------------------------------------
.cmdprcJMP
  jsr read_hex_addr       ; puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcJMP_fail
  ldx #$ff                ; reset stack pointer
  txs
  stz STDIN_IDX                 ; reset RX buffer index
  LED_OFF LED_BUSY
  jmp (FUNC_RES_L)
.cmdprcJMP_fail
  jmp cmdprc_fail 
