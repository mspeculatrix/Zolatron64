\ cmds_S.asm

\ ------------------------------------------------------------------------------
\ --- CMD: SAVE  :  SAVE MEMORY
\ ------------------------------------------------------------------------------
\ *** This is currently identical to DUMP. Might change this in the future
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
\ --- CMD: STAT  :  DISPLAY STATUS
\ ------------------------------------------------------------------------------
\ Usage: STAT
\ Output some useful info about registers etc.
.cmdprcSTAT
  ; --- LINE 1 -----------------
  stz STDOUT_IDX                              ; Set offset pointer
  LOAD_MSG stat_msg_lomem                     ; Show address of LOMEM
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda LOMEM                                   ; the end of the currently loaded
  sta TMP_ADDR_A_L                            ; program.
  lda LOMEM+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_fnres
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda FUNC_RESULT
  jsr display_stat_hex

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 2 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_faddr
  jsr OSSOAPP
  lda FILE_ADDR
  sta TMP_ADDR_A_L
  lda FILE_ADDR+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_fnerr
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda FUNC_ERR
  jsr display_stat_hex

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 3 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_pexit
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda PRG_EXIT_CODE
  jsr display_stat_hex

  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_exmem
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda EXTMEM_BANK
  jsr OSB2ISTR
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 4 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_sysreg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda SYS_REG
  jsr display_stat_hex

  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_stdin
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda STDIN_STATUS_REG
  jsr display_stat_hex

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 5 - Console-only  -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_sysreg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda SYS_REG
  jsr display_stat_bin

  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  LOAD_MSG stat_msg_spacer
  jsr OSSOAPP                                 ; Add to STDOUT_BUF

  LOAD_MSG stat_msg_stdin
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda STDIN_STATUS_REG
  jsr display_stat_bin

  jsr OSWRBUF
  NEWLINE

  jmp cmdprc_end

.display_stat_bin
  jsr OSB2BIN
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  rts

.display_stat_hex
  jsr OSB2HEX                                 ; Result will be in STR_BUF
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  rts

\ --- DATA --------------------
.stat_msg_lomem               ; For 'STAT' output
  equs "LOMEM:",0
.stat_msg_faddr
  equs "FADDR:",0
.stat_msg_fnerr
  equs "FNERR:",0
.stat_msg_fnres
  equs "FNRES:",0
.stat_msg_exmem
  equs "EXMEM:",0
.stat_msg_pexit
  equs "PEXIT:",0
.stat_msg_sysreg
  equs "SYSRG:",0
.stat_msg_stdin
  equs "STDIN:",0
.stat_msg_spacer
  equs "  ",0
