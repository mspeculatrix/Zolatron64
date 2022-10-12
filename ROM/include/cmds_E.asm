\ ------------------------------------------------------------------------------
\ --- CMD: EX  :  LOAD & EXECUTE PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: EX <filename>
\ Load a program to location USR_START and execute.
.cmdprcEX
  LED_ON LED_FILE_ACT
  jsr zd_getfile
  LED_OFF LED_FILE_ACT
  lda FUNC_ERR
  bne cmdprcEX_err
  jsr zd_fileload_ok
  jmp cmdprcRUN
.cmdprcEX_err
  LED_ON LED_ERR
  jmp cmdprc_fail
