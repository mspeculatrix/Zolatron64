\ ------------------------------------------------------------------------------
\ --- CMD: JMP  :  JUMP TO ADDRESS
\ ------------------------------------------------------------------------------
\ Jump to a specified address and execute from there.
\ Requires a two-byte address in hex.
.cmdprcJMP
  LOAD_MSG cmdprcJMP_msg
  jsr stdout_append
  jsr read_hex_addr         ; Read address. Puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcJMP_fail
  lda FUNC_RES_L
  sta TMP_ADDR_A
  lda FUNC_RES_H
  sta TMP_ADDR_A+1
  jsr uint16_to_hex_str     ; Puts hex string in STR_BUF
  jsr str_buf_to_msg_vec
  jsr stdout_append
  jsr stdout_to_msg_vec
  jsr OSLCDMSG
  ldx #$FF                  ; Reset stack pointer
  txs
  stz STDIN_IDX             ; Reset RX buffer index
  stz STDOUT_IDX
  stz STDOUT_BUF
  LED_OFF LED_BUSY
  jmp (FUNC_RES_L)          ; Make the jump
.cmdprcJMP_fail
  LOAD_MSG cmdprcJMP_msg_err
  jsr stdout_append
  LOAD_MSG STDOUT_BUF
  jsr OSLCDMSG
  jmp cmdprc_fail
.cmdprcJMP_msg
  equs "JUMP:",0
.cmdprcJMP_msg_err
  equs "Error",0
