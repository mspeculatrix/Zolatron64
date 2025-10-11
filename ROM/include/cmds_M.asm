\ ZolOS CLI Commands starting with 'M' - cmds_M.asm

\ ------------------------------------------------------------------------------
\ --- CMD: MV  :  MOVE FILE
\ ------------------------------------------------------------------------------
\ Usage: MV <curr_filename.ext> <new_filename.ext>
\ Rename a file.
\ ***** UNDER CONSTRUCTION *****
.cmdprcMV
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcMV_fail


  jmp cmdprcMV_success
.cmdprcMV_fail
  jmp cmdprc_fail
.cmdprcMV_success
  jmp cmdprc_success