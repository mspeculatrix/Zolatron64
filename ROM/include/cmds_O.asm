\ ZolOS CLI Commands starting with 'O' - cmds_O.asm

\ ------------------------------------------------------------------------------
\ --- CMD: OPEN  :  LOAD FILE INTO SPECIFIC ADDRESS
\ ------------------------------------------------------------------------------
\ Usage: OPEN <filename.ext> <start_address>
\ This is for loading any kind of file into a specific memory location.
\ The filename needs to include the extension.
.cmdprcOPEN
  LED_ON LED_FILE_ACT
  LOAD_MSG loading_msg
  jsr OSWRMSG
  jsr OSLCDMSG
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcOPEN_err
  jsr read_hex_addr           ; Puts address bytes in FUNC_RES_L, FUNC_RES_H
  lda FUNC_ERR
  bne cmdprcOPEN_err
  lda FUNC_RES_L              ; This is where we're going to put the code
  sta FILE_ADDR
  lda FUNC_RES_H
  sta FILE_ADDR + 1
  lda #ZD_OPCODE_DLOAD        ; Use opcode for loading data files
  jsr zd_loadfile
  LED_OFF LED_FILE_ACT
  lda FUNC_ERR
  bne cmdprcOPEN_err
  jmp cmdprcOPEN_success
.cmdprcOPEN_err
  LED_ON LED_ERR
  jmp cmdprc_fail
.cmdprcOPEN_success
  jsr zd_fileload_ok
  jmp cmdprc_success
