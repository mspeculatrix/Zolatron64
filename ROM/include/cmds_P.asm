\ cmds_P.asm

\ ------------------------------------------------------------------------------
\ --- CMD: PEEK  :  EXAMINE BYTE IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: PEEK <addr>
\ Show the value of a byte at a specific address.
\ Expects a two-byte hex address as input.
\ The command '?' also directs here.
.cmdprcPEEK
  jsr read_hex_addr         ; Get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPEEK_fail
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPEEK_fail       ; Should be null. Anything else is a mistake
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; Resulting string is in STR_BUF
  jsr duart_snd_strbuf
  jmp cmdprcPEEK_end
.cmdprcPEEK_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcPEEK_end
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: POKE  :  SET BYTE IN MEMORY
\ ------------------------------------------------------------------------------
\ Usage: POKE <addr> <val>
\ Write a one-byte value to a specific address.
\ Expects a two-byte hex address and a one-byte hex value as input.
\ The command '!' also directs here.
.cmdprcPOKE
  jsr read_hex_addr         ; Puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  jsr read_hex_byte         ; Get byte value - puts result in FUNC_RESULT
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  ldx STDIN_IDX
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPOKE_fail       ; Should be null. Anything else is a mistake
  lda FUNC_RESULT           ; Store the byte in the given address
  sta (FUNC_RES_L)
  jmp cmdprcPOKE_end
.cmdprcPOKE_fail
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprc_fail
.cmdprcPOKE_end
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: PRT  :  PRINT A FILE ... or something ... one day ... maybe ...
\ ------------------------------------------------------------------------------
.cmdprcPRT
  jmp cmdprc_success
