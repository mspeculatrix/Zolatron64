\ ------------------------------------------------------------------------------
\ --- CMD: SAVE  :  SAVE MEMORY
\ ------------------------------------------------------------------------------
\ *** This is currently a synonym for DUMP. Might change this in the future
\     to do something different. ***
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
  lda #ZD_OPCODE_SAVE_CRT             ; Set save type - in this case, CREATE
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
  LOAD_MSG stat_msg_lomem                     ; Show address of LOMEM - the
  jsr OSWRMSG                                 ; address of the first byte after
  lda LOMEM                                   ; the end of the currently loaded
  sta TMP_ADDR_A_L                            ; program.
  lda LOMEM+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  jsr display_stat_sbuf

  LOAD_MSG stat_msg_faddr
  jsr OSWRMSG
  lda FILE_ADDR
  sta TMP_ADDR_A_L
  lda FILE_ADDR+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  jsr display_stat_sbuf

  LOAD_MSG stat_msg_pexit
  lda PRG_EXIT_CODE
  jsr display_stat_hex

  LOAD_MSG stat_msg_fnerr
  lda FUNC_ERR
  jsr display_stat_hex

  LOAD_MSG stat_msg_fnres
  lda FUNC_RESULT
  jsr display_stat_hex

  LOAD_MSG stat_msg_exmem
  jsr OSWRMSG
  lda EXTMEM_BANK
  jsr OSB2ISTR
  jsr display_stat_sbuf

  jmp cmdprc_end

.display_stat_hex
  pha
  jsr OSWRMSG
  pla
  jsr OSB2HEX
.display_stat_sbuf
  jsr OSWRSBUF
  lda #' '
  jsr OSWRCH
  rts
