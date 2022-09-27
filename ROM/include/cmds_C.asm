\ cmds_C.asm

\ ------------------------------------------------------------------------------
\ --- CMD: CLEAR  :  CLEAR PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: CLEAR
\ Zeroes out a number of bytes, starting at USR_START, to effectively clear a
\ program from memory.
.cmdprcCLEAR
  ldx #0
.cmdprcCLEAR_loop
  stz USR_START,X
  inx
  cpx #CLEAR_BYTES
  bne cmdprcCLEAR_loop
  LOAD_MSG cdmprcCLEAR_msg
  jsr OSWRMSG
  NEWLINE
  jsr OSLCDMSG
  jmp cmdprc_success

\ --- DATA ------------------
.cdmprcCLEAR_msg
  equs "Program cleared",0
