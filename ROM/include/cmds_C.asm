\ ZolOS CLI Commands starting with 'C' - cmds_C.asm

\ ------------------------------------------------------------------------------
\ --- CMD: CHAIN  :  LOAD & EXECUTE PROGRAM
\ ------------------------------------------------------------------------------
\ Usage: CHAIN <filename>
\ Load a program from ZolaDOS persistent store to location USR_START and
\ execute. Assumes file extension is '.EXE' so you shouldn't provide this in
\ the filename
.cmdprcCHAIN
  LED_ON LED_FILE_ACT
  lda #MSG_SHOW
  jsr zd_getfile
  LED_OFF LED_FILE_ACT
  lda FUNC_ERR
  bne cmdprcCHAIN_err
  jsr zd_fileload_ok
  NEWLINE
  jmp cmdprcRUN
.cmdprcCHAIN_err
  LED_ON LED_ERR
  jmp cmdprc_fail

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

\ --- DATA ---------------------------------------------------------------------
.cdmprcCLEAR_msg
  equs "Program cleared",0
