\ ZolOS CLI Commands starting with 'T' - cmds_T.asm

\ ------------------------------------------------------------------------------
\ --- CMD: TIME  :  DISPLAY TIME
\ ------------------------------------------------------------------------------
.cmdprcTIME
  jsr rtc_read_time
  lda FUNC_ERR
  beq cmdprcTIME_display
  jmp cmdprc_fail
.cmdprcTIME_display
  ldx #2
.cmdprcTIME_loop
  lda RTC_CLK_BUF,X
  jsr OSB2ISTR
  dec FUNC_RESULT             ; Will start as 1 if result is not single digit
  bne cmdprcTIME_prt          ; 0 if single digit
  lda #'0'
  jsr OSWRCH
.cmdprcTIME_prt
  jsr OSWRSBUF
  cpx #0
  beq cmdprcTIME_done
  lda #':'
  jsr OSWRCH
  dex
  jmp cmdprcTIME_loop
.cmdprcTIME_done
  jmp cmdprc_success
