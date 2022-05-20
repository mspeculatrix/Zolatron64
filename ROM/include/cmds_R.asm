\-------------------------------------------------------------------------------
\ --- CMD: RUN  :  run a program at the standard user location               ---
\-------------------------------------------------------------------------------
.cmdprcRUN
  stz STDIN_IDX                 ; Reset RX buffer index
  stz PRG_EXIT_CODE             ; Reset Program Exit Code
  jmp USR_PAGE
