\ cmds_D.asm

\ ------------------------------------------------------------------------------
\ --- CMD: DEL  :  DELETE FILE ON SERVER
\ ------------------------------------------------------------------------------
\ Usage: DEL <filename.ext>
\ Delete a file on the ZolaDOS server.
\ Note that any extension must be specified (unlike LOAD and DUMP commands).

.cmdprcDEL
  LED_ON LED_FILE_ACT
  LOAD_MSG deleting_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jsr read_filename               ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcDEL_err
  jsr zd_delfile                  ; Delete file
  lda FUNC_ERR
  bne cmdprcDEL_err
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprcDEL_end
.cmdprcDEL_err
  jsr os_print_error              ; There should be an error code in FUNC_ERR
  jsr OSLCDERR
  jmp cmdprc_fail
.cmdprcDEL_end
  LED_OFF LED_FILE_ACT
  jmp cmdprc_success

\ ------------------------------------------------------------------------------
\ --- CMD: DUMP  :  DUMP MEMORY TO PERSISTENT STORE
\ ------------------------------------------------------------------------------
\ Usage: DUMP <start_addr> <end_addr> <filename>
\ Save a block of memory to ZolaDOS device.
\ The start and end addresses must be 4-char hex addresses.
\ Don't use an extension for the filename - '.BIN' will be appended
\ automatically by ZolaDOS.
.cmdprcDUMP
  LED_ON LED_FILE_ACT
  LOAD_MSG cdmprcDUMP_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jsr read_hex_addr_pair              ; Get addresses from input
  lda FUNC_ERR
  bne cmdprcDUMP_err
  jsr compare_tmp_addr                ; Check that address A is lower than B
  lda FUNC_RESULT                     ; Result should be 0 (LESS_THAN)
  bne cmdprcDUMP_addr_err
  jsr read_filename                   ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcDUMP_err
  ldx STDIN_IDX
  lda STDIN_BUF,X                 ; Check there's nothing left in the RX buffer
  bne cmdprcDUMP_synerr           ; Should be null. Anything else is a mistake
  lda #ZD_OPCODE_SAVE_CRT             ; Set save type - in this case, CREATE
  jsr zd_save_data                    ; Now save the memory contents
  lda FUNC_ERR
  bne cmdprcDUMP_err
  jmp cmdprcDUMP_success
.cmdprcDUMP_synerr
  lda #SYNTAX_ERR_CODE
  sta FUNC_ERR
  jmp cmdprcDUMP_err
.cmdprcDUMP_addr_err
  lda #ERR_ADDR
  sta FUNC_ERR
.cmdprcDUMP_err
  LED_OFF LED_FILE_ACT
  jmp cmdprc_fail                   ; Will display error in FUNC_ERR
.cmdprcDUMP_success
  LED_OFF LED_FILE_ACT
  LOAD_MSG file_act_complete_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jmp cmdprc_success

\ --- DATA ------------------
.cdmprcDUMP_msg
  equs "Dumping memory ... ",0
