\ ------------------------------------------------------------------------------
\ --- CMD: SAVE  :  SAVE MEMORY
\ ------------------------------------------------------------------------------
\ Save a block of memory to ZolaDOS device.
\ Usage: SAVE <start_addr> <end_addr> <filename>
\ The start and end addresses must be 4-char hex addresses.
.cmdprcSAVE
  LED_ON LED_FILE_ACT
  LOAD_MSG saving_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jsr read_hex_addr_pair              ; Get addresses from input
  lda FUNC_ERR
  bne cmdprcSAVE_err
  jsr compare_tmp_addr                ; Check that address A is lower than B
  lda FUNC_RESULT                     ; Result should be 0 (LESS_THAN)
  bne cmdprcSAVE_addr_err
  jsr read_filename                   ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcSAVE_err
  jsr zd_save_data                    ; Now save the memory contents
  lda FUNC_ERR
  beq cmdprcSAVE_success
  jmp cmdprcSAVE_err
.cmdprcSAVE_addr_err
  lda #ERR_ADDR
  sta FUNC_ERR
.cmdprcSAVE_err
  jsr OSWRERR
  jsr OSLCDERR
  jmp cmdprcSAVE_end
.cmdprcSAVE_success
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
.cmdprcSAVE_end
  LED_OFF LED_FILE_ACT
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
