\-------------------------------------------------------------------------------
\ --- CMD: PEEK  :  examine byte in memory                                   ---
\-------------------------------------------------------------------------------
.cmdprcPEEK
  jsr read_hex_addr         ; get address - puts bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPEEK_fail
  lda STDIN_BUF,X           ; check there's nothing left in the RX buffer
  bne cmdprcPEEK_fail       ; should be null. Anything else is a mistake
  lda (FUNC_RES_L)
  jsr byte_to_hex_str       ; resulting string is in STR_BUF
  jsr acia_prt_strbuf
  jmp cmdprcPEEK_end
.cmdprcPEEK_fail
  jmp cmdprc_fail
.cmdprcPEEK_end
  jmp cmdprc_end

\-------------------------------------------------------------------------------
\ --- CMD: POKE  :  set byte in memory                                       ---
\-------------------------------------------------------------------------------
.cmdprcPOKE
  jsr read_hex_addr         ; puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  jsr read_hex_byte         ; get byte value - puts result in FUNC_RESULT
  lda FUNC_ERR
  bne cmdprcPOKE_fail
  lda STDIN_BUF,X           ; check there's nothing left in the RX buffer
  bne cmdprcPOKE_fail       ; should be null. Anything else is a mistake
  lda FUNC_RESULT           ; store the byte in the given address
  ; --- debugging ----------------------
  ;jsr byte_to_hex_str
  ;jsr acia_prt_strbuf
  ; ------------------------------------
  sta (FUNC_RES_L)
  jmp cmdprcPOKE_end
.cmdprcPOKE_fail
  jmp cmdprc_fail
.cmdprcPOKE_end
  jmp cmdprc_end
  
\-------------------------------------------------------------------------------
\ --- CMD: PRT  :  one day...                                                ---
\-------------------------------------------------------------------------------
.cmdprcPRT
  jmp cmdprc_end
