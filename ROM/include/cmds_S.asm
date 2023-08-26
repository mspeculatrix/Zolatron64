\ ZolOS CLI Commands starting with 'S' - cmds_S.asm

\ ------------------------------------------------------------------------------
\ --- CMD: SAVE  :  SAVE PROGRAM
\ ------------------------------------------------------------------------------
\ Save the currently loaded program to persistent storage. Useful if we want to
\ save a copy of an executable under another name. Also might be useful for any
\ programs that are self-modifying or which store data within the program space.
\ Usage: SAVE <filename>
.cmdprcSAVE
  jsr check_exec                      ; Check executable code is loaded
  lda FUNC_ERR
  bne cmdprcSAVE_err
  SET_EXCL_EXT_FLAG
  jsr read_filename                   ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcSAVE_err
  ldx STDIN_IDX
  lda STDIN_BUF,X                     ; Check nothing left in the RX buffer
  bne cmdprcSAVE_synerr               ; Anything but null is a mistake
  LED_ON LED_FILE_ACT
  LOAD_MSG saving_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  lda #<USR_START                     ; Set memory addresses
  sta TMP_ADDR_A                      ;  "    "       "
  lda #>USR_START                     ;  "    "       "
  sta TMP_ADDR_A + 1                  ;  "    "       "
  lda PROG_END                        ;  "    "       "
  sta TMP_ADDR_B                      ;  "    "       "
  lda PROG_END + 1                    ;  "    "       "
  sta TMP_ADDR_B + 1                  ;  "    "       "
  lda #ZD_OPCODE_SAVE_CRT             ; Set save type - in this case, CREATE EXE
  jsr zd_save_data                    ; Now save the memory contents
  LED_OFF LED_FILE_ACT
  lda FUNC_ERR
  beq cmdprcSAVE_success
  jmp cmdprcSAVE_err
.cmdprcSAVE_synerr
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprcSAVE_err
.cmdprcSAVE_addr_err
  lda #ERR_ADDR
  sta FUNC_ERR
.cmdprcSAVE_err
  jmp cmdprc_fail
.cmdprcSAVE_success
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprc_success



\ ------------------------------------------------------------------------------
\ --- CMD: STAT  :  DISPLAY STATUS
\ ------------------------------------------------------------------------------
\ Usage: STAT
\ Output some useful info about registers etc.
.cmdprcSTAT
  ; --- LINE 1 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_progend
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda PROG_END                                   ; the end of the currently loaded
  sta TMP_ADDR_A_L                            ; program.
  lda PROG_END+1
  sta TMP_ADDR_A_H
  jsr uint16_to_hex_str                       ; Result will be in STR_BUF
  STR_BUF_TO_MSG_VEC                          ; Set MSG_VEC to point to this
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

  ; --- LINE 2 -----------------
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

  LOAD_MSG stat_msg_pexit
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda PRG_EXIT_CODE
  jsr display_stat_hex

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 3 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_sysreg
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda SYS_REG
  jsr display_stat_bin

  jsr OSWRBUF
  NEWLINE
  jsr OSLCDWRBUF

  ; --- LINE 4 -----------------
  stz STDOUT_IDX                              ; Set offset pointer

  LOAD_MSG stat_msg_stdin
  jsr OSSOAPP                                 ; Add to STDOUT_BUF
  lda STDIN_STATUS_REG
  jsr display_stat_bin

  jsr OSWRBUF
  jsr OSLCDWRBUF

  jmp cmdprc_success

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

\ --- DATA ---------------------------------------------------------------------
.stat_msg_lomem               ; For 'STAT' output
  equs "LOMEM:",0
.stat_msg_progend
  equs "PREND:",0
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
