\-------------------------------------------------------------------------------
\ --- CMD: BRK                                                               ---
\-------------------------------------------------------------------------------
.cmdprcBRK
  lda STDIN_BUF,X         ; check there's nothing left in the RX buffer
  bne cmdprcBRK_fail      ; should be null. Anything else is a mistake
  ldx #$ff                ; reset stack pointer
  txs
  stz STDIN_IDX                 ; reset RX buffer index
  LED_OFF LED_BUSY
  jmp ROMSTART            ; jump to start of ROM code
.cmdprcBRK_fail
  jmp cmdprc_fail

