\ ------------------------------------------------------------------------------
\ --- CMD: RUN  :  RUN PROGRAM
\ ------------------------------------------------------------------------------
\ Execute a program loaded at the standard user program location, USR_PAGE
.cmdprcRUN
  stz STDIN_BUF
  stz STDIN_IDX                 ; Reset RX buffer index
  stz PRG_EXIT_CODE             ; Reset Program Exit Code
  LED_OFF LED_BUSY
  jmp USR_PAGE
