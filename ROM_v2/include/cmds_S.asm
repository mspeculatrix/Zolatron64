\ ------------------------------------------------------------------------------
\ --- CMD: SAVE  :  SAVE MEMORY
\ ------------------------------------------------------------------------------
\ Save a block of memory to ZolaDOS device.
.cmdprcSAVE
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: STAT  :  PRINT STATUS
\ ------------------------------------------------------------------------------
\ Output some useful info.
.cmdprcSTAT
  LOAD_MSG stat_msg1
  jsr OSWRMSG
  lda LOMEM
  sta TMP_ADDR_A_L
  lda LOMEM+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH

  LOAD_MSG stat_msg2
  jsr OSWRMSG
  lda FUNC_ERR
  jsr OSB2HEX
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH

  LOAD_MSG stat_msg3
  jsr OSWRMSG
  lda EXTMEM_BANK
  jsr OSB2ISTR
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  jmp cmdprc_end
