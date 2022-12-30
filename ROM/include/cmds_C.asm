\ cmds_C.asm

\ ------------------------------------------------------------------------------
\ --- CMD: CLEAR  :  CLEAR PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: CLEAR
\ Zeroes out a number of bytes, starting at USR_START, to effectively clear a
\ program from memory.
\ ON EXIT : Resets LOMEM and PROG_END to USR_START
.cmdprcCLEAR
  ldx #0
.cmdprcCLEAR_loop
  stz USR_START,X
  inx
  cpx #CLEAR_BYTES
  bne cmdprcCLEAR_loop
  lda #<USR_START
  sta LOMEM
  sta PROG_END
  lda #>USR_START
  sta LOMEM + 1
  sta PROG_END + 1
  LOAD_MSG cdmprcCLEAR_msg
  jsr OSWRMSG
  NEWLINE
  jsr OSLCDMSG
  jmp cmdprc_success

\ --- DATA ------------------
.cdmprcCLEAR_msg
  equs "Program cleared",0
