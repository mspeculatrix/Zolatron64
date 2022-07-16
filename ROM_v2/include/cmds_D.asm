\ ------------------------------------------------------------------------------
\ --- CMD: DEL  :  DELETE FILE ON SERVER
\ ------------------------------------------------------------------------------
\ Delete a file on the ZolaDOS server.

.cmdprcDEL
  LED_ON LED_FILE_ACT
  LOAD_MSG deleting_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcDEL_err
  jsr zd_delfile              ; Delete file
  lda FUNC_ERR
  bne cmdprcDEL_err
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprcDEL_end
.cmdprcDEL_err
  jsr os_print_error          ; There should be an error code in FUNC_ERR
  jsr OSLCDERR
.cmdprcDEL_end
  LED_OFF LED_FILE_ACT
  jmp cmdprc_end
  