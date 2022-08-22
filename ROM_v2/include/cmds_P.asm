\ ------------------------------------------------------------------------------
\ --- CMD: PEEK  :  EXAMINE BYTE IN MEMORY
\ ------------------------------------------------------------------------------
.cmdprcPEEK
  jsr read_hex_addr         ; Get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPEEK_fail
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPEEK_fail       ; Should be null. Anything else is a mistake
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; Resulting string is in STR_BUF
  jsr duart_snd_strbuf
  jmp cmdprcPEEK_end
.cmdprcPEEK_fail
  jmp cmdprc_fail
.cmdprcPEEK_end
  jmp cmdprc_end

\ ------------------------------------------------------------------------------
\ --- CMD: POKE  :  SET BYTE IN MEMORY
\ ------------------------------------------------------------------------------
.cmdprcPOKE
  jsr read_hex_addr         ; Puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  jsr read_hex_byte         ; Get byte value - puts result in FUNC_RESULT
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  lda STDIN_BUF,X           ; Check there's nothing left in the RX buffer
  bne cmdprcPOKE_fail       ; Should be null. Anything else is a mistake
  lda FUNC_RESULT           ; Store the byte in the given address
  sta (FUNC_RES_L)
  jmp cmdprcPOKE_end
.cmdprcPOKE_fail
  jmp cmdprc_fail
.cmdprcPOKE_end
  jmp cmdprc_end
  
\ ------------------------------------------------------------------------------
\ --- CMD: PRT  :  PRINT A FILE ... one day...
\ ------------------------------------------------------------------------------
.cmdprcPRT
  jmp cmdprc_end
