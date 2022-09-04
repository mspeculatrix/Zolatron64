\ cmds_B.asm

\ ------------------------------------------------------------------------------
\ --- CMD: BRK  :  PERFORM SOFT RESET
\ ------------------------------------------------------------------------------
\ Usage: BRK
.cmdprcBRK
  lda STDIN_BUF,X         ; Check there's nothing left in the RX buffer
  bne cmdprcBRK_fail      ; Should be null. Anything else is a mistake
  ldx #$FF                ; Reset stack pointer. Why not?
  txs
  stz STDIN_IDX           ; Reset RX buffer index
  LED_OFF LED_BUSY        ; Make sure this is off
  jmp ROMSTART            ; Jump to start of ROM code
.cmdprcBRK_fail
  jmp cmdprc_fail
