\ cmds_M.asm

\ ------------------------------------------------------------------------------
\ --- CMD: MV  :  MOVE FILE
\ ------------------------------------------------------------------------------
\ Usage: MV <curr_filename> <new_filename>
\ Rename a file.
.cmdprcMV
  jsr read_filename           ; Puts filename in STR_BUF
  lda FUNC_ERR
  bne cmdprcMV_fail


  jmp cmdprcMV_success
.cmdprcMV_fail
  jmp cmdprc_fail
.cmdprcMV_success
  jmp cmdprc_success